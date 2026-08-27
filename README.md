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
| `PASSTHROUGH_ENV` | | Space-separated environment variable names passed to interactive shells and `aipod run` |
| `USE_RUST` | `true` | Install Rust via rustup, cargo, and ripgrep (nice for Claude Code) |
| `USE_NPM` | `true` | Install nvm and Node.js 25 |
| `USE_UV` | `true` | Install uv (Python package manager) |
| `USE_CLAUDE_CODE` | `true` | Install Claude Code CLI |
| `USE_CODEX` | `true` | Install OpenAI Codex (requires USE_NPM) |
| `USE_COPILOT` | `true` | Install GitHub Copilot CLI (requires USE_NPM) |
| `USE_PI` | `true` | Install Pi coding agent (requires USE_NPM) |
| `USE_AGY` | `true` | Install Antigravity CLI |
| `USE_MISE` | `false` | Install mise |
| `USE_OVERMIND` | `false` | Install overmind (process manager for Procfile-based apps) |
| `USE_JUST` | `false` | Install just (command runner) |
| `CAP_ADD` | | Space-separated Linux capabilities to add to the container (eg: `PERFMON SYS_ADMIN` for `perf`) |
| `CREATE_ARGS` | | Extra arguments passed verbatim to `podman run` when the container is created |

Remove any `USE_*` to remove a toolchain, or set it to `false`.

Some useful `CREATE_ARGS` recipes:

| Recipe | Effect |
|--------|--------|
| `--userns keep-id:uid=1000,gid=1000` | Match mounted file ownership to the host user (Linux; requires podman 4.3+) |
| `--security-opt seccomp=unconfined` | Let `perf` record software events by disabling the default seccomp filter. Weakens the sandbox |
| `--memory 8g` | Cap container memory |

Arguments apply when the container is created, so changing `CREATE_ARGS` requires `aipod clean` (or a container recreation) to take effect. Argument values containing spaces are not supported.

To expose credentials without storing them in the container configuration, list
their variable names in `PASSTHROUGH_ENV`. Values are read from aipod's environment
when it opens a shell or runs a command. For example, this retrieves the GitHub
token from the GitHub CLI credential store without writing the token to the config:

```sh
PASSTHROUGH_ENV="GH_TOKEN"
GH_TOKEN="$(gh auth token)"
```

The variables are available to the launched process and its children. They are not
added to the container's persistent environment.
