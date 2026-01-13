# Aipod

Afraid of an AI agent going wild?

This is a container configuration that I'm using for yoloing AI agents.

## Usage

```bash
$ make
[... 5 minutes later ... ]
aipod% ls -la
total 16
drwx------. 1 developer aipod   80 Jan 13 22:47 .
drwxr-xr-x. 1 root  root    19 Jan 13 22:47 ..
-rw-r--r--. 1 developer aipod  220 Jan  2 14:02 .bash_logout
-rw-r--r--. 1 developer aipod 3552 Jan 13 22:47 .bashrc
drwxr-xr-x. 4 developer aipod   28 Jan 13 22:47 .config
drwxr-xr-x. 3 developer aipod   17 Jan 13 22:47 .local
-rw-r--r--. 1 developer aipod  833 Jan 13 22:47 .profile
-rw-r--r--. 1 developer aipod   26 Jan 13 22:47 .zshrc
```

All necessary developer packages are installed, so `curl` one-liners work.

If you want to remove the container (warning: all your data will be lost), just:

```bash
make clean
```

## Configuration

Change `container.conf` with your `USERNAME`, `HOSTNAME` and `CHEZMOI_DOTFILES_REPO` of preference.

## Requirements

- [podman](https://podman.io/)
