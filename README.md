# zsh-tmux

A Zsh plugin for dynamic [tmux](https://github.com/tmux/tmux) window title management based on current shell activity.

## Features

- Automatic window title updates based on running command
- Shows "zsh" when idle at prompt
- Displays command name during execution
- Resolves job references (`fg`, `%1`) to actual command names
- Automatic title truncation (max 20 characters)

## Requirements

- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer

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

## API Reference

### Functions

#### `update_title`

Sets the tmux window title with automatic truncation.

```zsh
update_title <title>
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `title` | Yes | Title text to display |

**Behavior:**

- Maximum 20 characters displayed
- Longer titles truncated with `...` suffix
- Newlines stripped
- Percent signs escaped

**Example:**

```zsh
update_title "vim"
update_title "very-long-command-name"  # Shows: "very-long-comman..."
```

### Hook Functions

These are automatically registered and should not be called directly:

#### `_zsh_title__precmd`

Executed before each prompt. Sets title to `zsh`.

#### `_zsh_title__preexec`

Executed before command execution. Sets title to command name.

**Features:**

- Extracts first word of command
- Resolves job references:
  - `fg` -> actual job command
  - `%1`, `%+` -> job command text

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

## Directory Structure

```
zsh-tmux/
├── zsh-tmux.plugin.zsh   # Main plugin with all functions and hooks
├── README.md
└── LICENSE
```

## License

MIT License - see [LICENSE](./LICENSE) for details.
