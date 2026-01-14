# Aipod

Afraid of an AI agent going wild?

This is a _lightly opinionated_ configuration that I'm using for yoloing AI agents.

## Usage

```bash
$ aipod
[... 5 minutes later ... ]
aipod% ls -la
total 76
drwx------. 1 developer developer    24 Jan 14 13:11 .
drwxr-xr-x. 1 root      root         23 Jan 14 13:10 ..
-rw-r--r--. 1 developer developer   220 Jan  2 14:02 .bash_logout
-rw-r--r--. 1 developer developer  3573 Jan 14 13:10 .bashrc
drwxr-xr-x. 4 developer developer   157 Jan 14 13:10 .cargo
drwxr-xr-x. 4 developer developer    28 Jan 14 13:10 .config
drwxr-xr-x. 3 developer developer    17 Jan 14 13:10 .local
drwxr-xr-x. 8 developer developer  4096 Jan 14 13:11 .nvm
-rw-r--r--. 1 developer developer   854 Jan 14 13:10 .profile
drwxr-xr-x. 6 developer developer    94 Jan 14 13:10 .rustup
-rw-r--r--. 1 developer developer 49375 Jan 14 13:11 .zcompdump
-rw-r--r--. 1 developer developer    21 Jan 14 13:10 .zshenv
-rw-r--r--. 1 developer developer   223 Jan 14 13:11 .zshrc
```

All necessary developer packages are installed, so `curl` one-liners work.

If you want to remove the container (warning: all your data will be lost), just:

```bash
aipod clean
```

## Requirements

- [podman](https://podman.io/)

## Configuration

Customize `aipod.conf` to your liking:

| Variable | Default | Description |
|----------|---------|-------------|
| `USERNAME` | `developer` | User name |
| `HOSTNAME` | `aipod` | Name of the container |
| `CHEZMOI_DOTFILES_REPO` | | GitHub repo for [chezmoi](https://www.chezmoi.io/) dotfiles (eg: `user/dotfiles`). Does nothing if blank |
| `USE_RUST` | `true` | Install Rust via rustup, cargo, and ripgrep (nice for Claude Code) |
| `USE_NPM` | `true` | Install nvm and Node.js 25 |
| `USE_UV` | `true` | Install uv (Python package manager) |
| `USE_CLAUDE_CODE` | `true` | Install Claude Code CLI |
| `USE_CODEX` | `true` | Install OpenAI Codex (requires USE_NPM) |

Remove any `USE_*` to remove a toolchain, or set it to `false`.
