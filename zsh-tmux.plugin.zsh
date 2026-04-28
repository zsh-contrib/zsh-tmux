#!/usr/bin/env zsh
#

# Return 0 when the environment indicates the shell is running inside a
# tmux or GNU screen session, i.e. when emitting the screen/tmux
# title-setting escape (`ESC k <title> ESC \`, introduced by `ESC k` and
# terminated by ST) is expected to be consumed by the multiplexer.
#
# This is an environment-based heuristic, not a terminal capability
# probe: a user could in principle export TERM=tmux-256color or
# TERM=screen-256color without actually being inside tmux/screen, in
# which case the payload would still leak. Those configurations are
# self-inflicted; the common cases (real tmux child processes, nested
# shells via ssh, bare `screen`) are all covered.
#
# Why this matters: the `ESC k ... ST` sequence is a screen/tmux-private
# control, not part of the ECMA-48 string-control family
# (DCS/OSC/APC/PM/SOS all use distinct introducers). Terminals that
# aren't screen or tmux don't recognise `ESC k` and render the payload
# as literal text, making every command look like it's being echoed back
# to the user.
function _zsh_title__in_tmux_or_screen() {
  [[ -n "$TMUX" ]] && return 0
  case "$TERM" in
    tmux*|screen*) return 0 ;;
  esac
  return 1
}

# Return 0 when the current terminal is expected to understand the OSC 0
# window-title sequence (`\e]0;<title>\a`). OSC 0 is the de-facto xterm
# standard and is honoured by essentially every modern terminal; this
# check is mostly a safety rail for explicitly dumb terminals (pipes,
# `TERM=dumb`, plain `linux` console, etc.) where emitting OSC would be
# at best wasted bytes and at worst leak text into a pager.
function _zsh_title__supports_osc_title() {
  [[ -t 1 ]] || return 1
  case "$TERM" in
    ''|dumb|linux|cons25|unknown) return 1 ;;
  esac
  return 0
}

function update_title() {
  emulate -L zsh -o extendedglob
  setopt localoptions no_shwordsplit

  # Opt-out: users who set ZSH_TMUX_DISABLE_TITLE=1 get a complete no-op.
  [[ "${ZSH_TMUX_DISABLE_TITLE:-0}" == 1 ]] && return 0

  # parameters
  local title

  # prepare the title
  title=${(V)1//\%/\%\%}
  title=$(print -n -- "%20>...>$title")
  title=${title//$'\n'/}

  # Expand prompt escapes once so both branches see the same text.
  local expanded=${(%)title}

  if _zsh_title__in_tmux_or_screen; then
    # Inside tmux/screen: emit the screen/tmux title-setting escape
    # (`ESC k <title> ESC \`). This is the plugin's original behaviour
    # and the reason it exists; tmux/screen consume the sequence and
    # update the window name.
    printf '\033k%s\033\\' "$expanded"
  elif _zsh_title__supports_osc_title; then
    # Outside tmux/screen: set the terminal window title via OSC 0, so
    # users on Ghostty, Kitty, iTerm2, Apple Terminal, Alacritty, etc.
    # still get live "what is this pane doing" titles without leaking
    # the screen/tmux title escape into the buffer.
    printf '\033]0;%s\a' "$expanded"
  fi
}

# called just before the prompt is printed
function _zsh_title__precmd() {
  emulate -L zsh
  update_title "zsh"
}

# called just before a command is executed
function _zsh_title__preexec() {
  emulate -L zsh
  setopt localoptions no_shwordsplit

  # Work on a copy; don't assign to $1.
  local line=$1

  # Escape backslashes so ${(z)...} re-parses correctly.
  line=${line//\\/\\\\\\\\}

  # Re-parse the command line into words
  local -a words
  words=(${(z)line})

  # Resolve job references (fg or %N) to their real command text, if available.
  local job_spec
  case $words[1] in
    fg) job_spec=${(Q)${words[2]:-%+}} ;;
    %*) job_spec=${(Q)words[1]} ;;
  esac

  if [[ -n $job_spec && -n ${jobtexts[$job_spec]} ]]; then
    words=(${(z)jobtexts[$job_spec]})
  fi

  # Join words for display
  # local cmd_name=${(j: :)words}
  local cmd_name="${words[1]}"
  update_title "$cmd_name"
}

autoload -Uz add-zsh-hook

add-zsh-hook precmd _zsh_title__precmd
add-zsh-hook preexec _zsh_title__preexec
