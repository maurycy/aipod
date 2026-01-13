# Aipod

Afraid of an AI agent going wild?

This is a container configuration that I'm using for yoloing AI agents.

## Usage

```bash
$ make
[... 5 minutes later ... ]
[1] 2026-01-13T22:36:16.886729449+0000 developer@aipod /home/developer %
```

All necessary developer packages are installed, so all `curl` one-liners work.

If you want to remove the container (warning: all your data will be lost), just:

```bash
make clean
```

## Configuration

Change `container.conf` with your `USERNAME` and `HOSTNAME` of preference.

## Requirements

- [podman](https://podman.io/)
