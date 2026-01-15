# Aipod

Afraid of a code agent going wild? Contain it in [podman](https://podman.io/).

**Work in progress.**

## Installation

```bash
install.sh: install, upgrade, or remove aipod

Usage: install.sh [-t tag] [-s] <command>

Commands:
    install     Clone aipod to ~/.local/share/aipod and symlink to ~/.local/bin
    upgrade     Pull latest changes from git
    uninstall   Remove aipod (config preserved)

Options:
    -t tag      Install specific git tag or branch (default: main)
    -s          Install from current directory (copies working tree)
    -h          Show this help
```

## Usage

```bash
aipod: manage development container

Usage: aipod [command] [options]

Commands:
    up          Start container interactively
    down        Stop the container
    status      Show container status
    clean       Remove container, image, and config

    run         Run command in container
    cp          Copy file/directory to container

    mount       Add local directory to container
    unmount     Remove local directory from container
    port        Expose container port
    close       Remove port mapping

    config      Edit the configuration
    help        Show this help

Mounting directories:
    aipod mount                     Mount current directory to home
    aipod mount <path>              Mount path to home/basename
    aipod mount <path> <remote>     Mount path to specified container path
    aipod unmount                   Remove all mounts
    aipod unmount <path>            Remove mount for specified path

Port usage:
    aipod port <port>               Expose container port to same host port
    aipod port <port> <host>        Expose container port to specified host port
    aipod close <port>              Remove port mapping for container port
    aipod close                     Remove all port mappings

Run usage:
    aipod run <command> [args...]   Run command in container at translated CWD

Copying:
    aipod cp <file|directory>       Copy file/directory to container
```

## Requirements

- [podman](https://podman.io/)

## Configuration

Customize the container to your liking:

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
