#!/usr/bin/env zsh
#
function update_title() {
  emulate -L zsh -o extendedglob
  setopt localoptions no_shwordsplit

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
  local cmd_name=${(j: :)words}
  update_title "$cmd_name"
}

autoload -Uz add-zsh-hook

add-zsh-hook precmd _zsh_title__precmd
add-zsh-hook preexec _zsh_title__preexec
