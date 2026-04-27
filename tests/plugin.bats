#!/usr/bin/env bats

# Tests for zsh-tmux plugin
#
# Requires bats-core: https://github.com/bats-core/bats-core
# Run: bats tests/plugin.bats

export PLUGIN_DIR
PLUGIN_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# ---------------------------------------------------------------------------
# update_title
# ---------------------------------------------------------------------------

@test "update_title: output contains the title text" {
  run zsh -c '
    export TMUX=test
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "vim"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"vim"* ]]
}

@test "update_title: long title output contains ellipsis" {
  run zsh -c '
    export TMUX=test
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "this-is-a-very-long-command-name"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"..."* ]]
}

@test "update_title: percent signs in title are escaped" {
  run zsh -c '
    export TMUX=test
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "100%done"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"done"* ]]
}

@test "update_title: wraps title in tmux escape sequence" {
  run zsh -c '
    export TMUX=test
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "zsh"
  '
  [[ "$status" -eq 0 ]]
  # ESC k ... ESC backslash
  [[ "$output" == $'\033k'*$'\033\\'* ]]
}

@test "update_title: emits DCS sequence inside tmux/screen (TMUX set)" {
  run zsh -c '
    export TMUX=test
    unset TERM
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "hermes"
  '
  [[ "$status" -eq 0 ]]
  # ESC k hermes ESC backslash
  [[ "$output" == $'\033k'*"hermes"*$'\033\\'* ]]
}

@test "update_title: emits OSC 0 sequence outside tmux/screen" {
  run zsh -c '
    unset TMUX
    export TERM=xterm-256color
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    # Force the OSC path: under bats, stdout is not a tty, so stub the
    # capability check so we can observe what update_title emits.
    _zsh_title__supports_osc_title() { return 0; }
    update_title "hermes"
  '
  [[ "$status" -eq 0 ]]
  # ESC ] 0 ; hermes BEL
  [[ "$output" == $'\033]0;'*"hermes"*$'\a'* ]]
  # And must NOT contain the DCS sequence
  [[ "$output" != *$'\033k'* ]]
}

@test "update_title: emits nothing on dumb terminal outside tmux/screen" {
  run zsh -c '
    unset TMUX
    export TERM=dumb
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    _zsh_title__supports_osc_title() { return 1; }
    update_title "hermes"
  '
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}

@test "update_title: ZSH_TMUX_DISABLE_TITLE=1 silences everything" {
  run zsh -c '
    export TMUX=test
    export ZSH_TMUX_DISABLE_TITLE=1
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "hermes"
  '
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}

@test "update_title: emits DCS when TERM is screen*" {
  run zsh -c '
    unset TMUX
    export TERM=screen-256color
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "hermes"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'\033k'*"hermes"*$'\033\\'* ]]
}

@test "update_title: emits DCS when TERM is tmux*" {
  run zsh -c '
    unset TMUX
    export TERM=tmux-256color
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title "hermes"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'\033k'*"hermes"*$'\033\\'* ]]
}

# ---------------------------------------------------------------------------
# _zsh_title__precmd
# ---------------------------------------------------------------------------

@test "_zsh_title__precmd: calls update_title with 'zsh'" {
  run zsh -c '
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title() { echo "$1"; }
    _zsh_title__precmd
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == "zsh" ]]
}

# ---------------------------------------------------------------------------
# _zsh_title__preexec
# ---------------------------------------------------------------------------

@test "_zsh_title__preexec: uses first word of command as title" {
  run zsh -c '
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title() { echo "$1"; }
    _zsh_title__preexec "vim file.txt"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == "vim" ]]
}

@test "_zsh_title__preexec: uses first word from multi-word pipeline" {
  run zsh -c '
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title() { echo "$1"; }
    _zsh_title__preexec "npm run build"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == "npm" ]]
}

@test "_zsh_title__preexec: single-word command is used as-is" {
  run zsh -c '
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title() { echo "$1"; }
    _zsh_title__preexec "top"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == "top" ]]
}

@test "_zsh_title__preexec: fg with no active jobs uses fg as title" {
  # jobtexts is read-only in non-interactive zsh; without active jobs fg falls
  # back to the literal command name rather than resolving to a job command.
  run zsh -c '
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title() { echo "$1"; }
    _zsh_title__preexec "fg"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == "fg" ]]
}

@test "_zsh_title__preexec: %+ with no active jobs uses %+ as title" {
  run zsh -c '
    source "$PLUGIN_DIR/zsh-tmux.plugin.zsh"
    update_title() { echo "$1"; }
    _zsh_title__preexec "%+"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == "%+" ]]
}
