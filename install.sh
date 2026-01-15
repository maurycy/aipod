#!/bin/sh
set -e

REPO="https://github.com/maurycy/aipod.git"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aipod"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/aipod"
TAG=""
USE_SOURCE="false"

usage() {
	cat <<EOF
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
EOF
}

log_info() {
	printf 'info: %s\n' "$*"
}

log_err() {
	printf 'error: %s\n' "$*" >&2
}

check_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		log_err "$1 is required but not found"
		exit 1
	fi
}

cmd_install() {
	if [ -d "$SHARE_DIR" ]; then
		log_err "aipod already installed at $SHARE_DIR"
		log_err "run 'install.sh upgrade' to update, or 'install.sh uninstall' first"
		exit 1
	fi

	# Create directories
	mkdir -p "$SHARE_DIR"
	mkdir -p "$BIN_DIR"

	if [ "$USE_SOURCE" = "true" ]; then
		if [ -n "$TAG" ]; then
			log_err "tag option is not supported with local source installs"
			exit 1
		fi
		if [ ! -f "./aipod" ]; then
			log_err "current directory missing aipod: $(pwd)"
			exit 1
		fi
		if [ ! -f "./Containerfile" ]; then
			log_err "current directory missing Containerfile: $(pwd)"
			exit 1
		fi

		log_info "copying aipod from $(pwd) to $SHARE_DIR"
		tar -cf - --exclude .git . | (cd "$SHARE_DIR" && tar -xf -)
	else
		check_cmd git
		# Clone repository (disable credential prompts for public repo)
		log_info "cloning aipod to $SHARE_DIR"
		GIT_TERMINAL_PROMPT=0 git clone "$REPO" "$SHARE_DIR"
	fi

	# Checkout specific tag if requested
	if [ -n "$TAG" ]; then
		log_info "checking out $TAG"
		(cd "$SHARE_DIR" && git checkout "$TAG")
	fi

	# Create symlink (remove existing file or symlink)
	if [ -e "$BIN_DIR/aipod" ] || [ -L "$BIN_DIR/aipod" ]; then
		rm "$BIN_DIR/aipod"
	fi
	ln -s "$SHARE_DIR/aipod" "$BIN_DIR/aipod"
	log_info "created symlink $BIN_DIR/aipod"

	# Restore config from backup, or create from example
	if [ -f "$CONFIG_DIR/aipod.conf" ]; then
		cp "$CONFIG_DIR/aipod.conf" "$SHARE_DIR/aipod.conf"
		log_info "restored config from $CONFIG_DIR/aipod.conf"
	elif [ -f "$SHARE_DIR/aipod.conf.example" ]; then
		cp "$SHARE_DIR/aipod.conf.example" "$SHARE_DIR/aipod.conf"
		log_info "created config at $SHARE_DIR/aipod.conf"
	fi

	log_info "aipod installed successfully"

	# Check if BIN_DIR is in PATH
	case ":$PATH:" in
	*":$BIN_DIR:"*) ;;
	*)
		printf '\n'
		log_info "add %s to your PATH:\n" "$BIN_DIR"
		printf '    export PATH="%s:$PATH"\n' "$BIN_DIR"
		;;
	esac
}

cmd_upgrade() {
	if [ ! -d "$SHARE_DIR" ]; then
		log_err "aipod not installed at $SHARE_DIR"
		log_err "run 'install.sh install' first"
		exit 1
	fi

	check_cmd git

	log_info "upgrading aipod"
	(cd "$SHARE_DIR" && git pull --ff-only)

	# Show current version
	commit="$(cd "$SHARE_DIR" && git rev-parse --short HEAD)"
	log_info "aipod upgraded to $commit"
}

cmd_uninstall() {
	if [ ! -d "$SHARE_DIR" ] && [ ! -L "$BIN_DIR/aipod" ]; then
		log_err "aipod not installed"
		exit 1
	fi

	# Preserve config before removing source
	if [ -f "$SHARE_DIR/aipod.conf" ]; then
		mkdir -p "$CONFIG_DIR"
		cp "$SHARE_DIR/aipod.conf" "$CONFIG_DIR/aipod.conf"
		log_info "config preserved at $CONFIG_DIR/aipod.conf"
	fi

	# Remove symlink
	if [ -L "$BIN_DIR/aipod" ]; then
		rm "$BIN_DIR/aipod"
		log_info "removed $BIN_DIR/aipod"
	fi

	# Remove source
	if [ -d "$SHARE_DIR" ]; then
		rm -rf "$SHARE_DIR"
		log_info "removed $SHARE_DIR"
	fi

	log_info "aipod removed"
}

main() {
	while getopts "t:sh" opt; do
		case "$opt" in
		t) TAG="$OPTARG" ;;
		s) USE_SOURCE="true" ;;
		h)
			usage
			exit 0
			;;
		*)
			usage
			exit 1
			;;
		esac
	done
	shift $((OPTIND - 1))

	case "${1:-install}" in
	install) cmd_install ;;
	upgrade | update) cmd_upgrade ;;
	uninstall | deinstall | remove) cmd_uninstall ;;
	help | usage | "") usage ;;
	*)
		usage
		exit 1
		;;
	esac
}

main "$@"
