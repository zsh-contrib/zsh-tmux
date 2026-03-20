# zsh-tmux

Automatic tmux window title management for Zsh — live updates as commands run.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Know at a glance what every pane is doing. `zsh-tmux` hooks into Zsh's precmd and preexec to keep your tmux window titles in sync — idle panes show `zsh`, running panes show the command name, and job references like `fg` resolve to the actual process.

## Requirements

- [tmux](https://github.com/tmux/tmux) (`tmux`)

**macOS (Homebrew):**

```bash
brew install tmux
```

**Nix:**

```bash
nix profile install nixpkgs#tmux
```

## Installation

### Using zinit

```zsh
zinit load zsh-contrib/zsh-tmux
```

### Using sheldon

```toml
[plugins.zsh-tmux]
github = "zsh-contrib/zsh-tmux"
```

### Manual

```zsh
git clone https://github.com/zsh-contrib/zsh-tmux.git ~/.zsh/plugins/zsh-tmux
source ~/.zsh/plugins/zsh-tmux/zsh-tmux.plugin.zsh
```

## Behavior

| State | Window Title |
|-------|--------------|
| Idle at prompt | `zsh` |
| Running `vim file.txt` | `vim` |
| Running `npm run build` | `npm` |
| Long command name | Truncated with `...` |

Titles are capped at 20 characters and have newlines stripped and percent signs escaped.

## Configuration

### Conditional Loading

Only load when inside tmux:

```zsh
if [[ -n "$TMUX" ]]; then
  zinit load zsh-contrib/zsh-tmux
fi
```

### Tmux Configuration

Ensure tmux is configured to display window titles:

```tmux
# ~/.tmux.conf
set -g set-titles on
set -g set-titles-string "#W"
```

## API Reference

### `update_title <title>`

Sets the tmux window title with automatic truncation.

```zsh
update_title "vim"
update_title "very-long-command-name"  # shows: "very-long-comman..."
```

### Hook Functions

Registered automatically — do not call directly.

| Hook | Trigger | Action |
|------|---------|--------|
| `_zsh_title__precmd` | Before each prompt | Sets title to `zsh` |
| `_zsh_title__preexec` | Before command execution | Sets title to command name |

`_zsh_title__preexec` extracts the first word of the command and resolves job references (`fg`, `%1`, `%+`) to the actual command text.

## The zsh-contrib Ecosystem

| Repo | What it provides |
|------|-----------------|
| [zsh-aws](https://github.com/zsh-contrib/zsh-aws) | AWS credential management with aws-vault and tmux |
| [zsh-eza](https://github.com/zsh-contrib/zsh-eza) | eza with Catppuccin and Rose Pine theming |
| [zsh-fzf](https://github.com/zsh-contrib/zsh-fzf) | fzf with Catppuccin and Rose Pine theming |
| [zsh-op](https://github.com/zsh-contrib/zsh-op) | 1Password CLI with secure caching and SSH key management |
| **zsh-tmux** ← you are here | Automatic tmux window title management |
| [zsh-vivid](https://github.com/zsh-contrib/zsh-vivid) | vivid LS_COLORS generation with theme support |

## License

[MIT](LICENSE) — Copyright (c) 2025 zsh-contrib

<!-- markdownlint-disable-file MD013 -->
