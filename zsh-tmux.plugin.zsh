#!/usr/bin/env zsh
#

# Return 0 when the current terminal understands the DCS title sequence
# (`\ek<title>\e\\`), which is specific to tmux / GNU screen. Everywhere
# else the sequence is not recognised and terminals such as Ghostty, Kitty
# or Apple Terminal render the payload as literal text on the next line,
# making it look like every command is being echoed back to the user.
function _zsh_title__in_tmux_or_screen() {
  [[ -n "$TMUX" ]] && return 0
  case "$TERM" in
    tmux*|screen*) return 0 ;;
  esac
  return 1
}

function update_title() {
  emulate -L zsh -o extendedglob
  setopt localoptions no_shwordsplit

  # Only emit the DCS title sequence when it will actually be consumed.
  # Outside tmux/screen this escape is invalid and leaks the title text
  # onto the terminal (see issue: commands echoed after Enter).
  _zsh_title__in_tmux_or_screen || return 0

  # parameters
  local title

  # prepare the title
  title=${(V)1//\%/\%\%}
  title=$(print -n -- "%20>...>$title")
  title=${title//$'\n'/}

  printf '\033k%s\033\\' "${(%)title}"
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
