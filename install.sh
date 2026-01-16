#!/bin/sh
set -e

# aipod installer - idempotent, works with curl | sh
# Usage: curl -fsSL https://raw.githubusercontent.com/maurycy/aipod/main/install.sh | sh

RAW_URL="https://raw.githubusercontent.com/maurycy/aipod/main"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aipod"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/aipod"
BIN_DIR="$HOME/.local/bin"

log_info() {
	printf 'info: %s\n' "$*"
}

log_err() {
	printf 'error: %s\n' "$*" >&2
}

is_local_source() {
	script_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || return 1
	[ -f "${script_dir}/aipod" ] && [ -f "${script_dir}/Containerfile" ]
}

install_from_local() {
	script_dir="$(cd "$(dirname "$0")" && pwd)"
	log_info "installing from local source: ${script_dir}"
	cp "${script_dir}/aipod" "${DATA_DIR}/aipod"
	cp "${script_dir}/Containerfile" "${DATA_DIR}/Containerfile"
	[ -f "${script_dir}/aipod.conf.example" ] && cp "${script_dir}/aipod.conf.example" "${DATA_DIR}/aipod.conf.example"
}

install_from_remote() {
	log_info "downloading from ${RAW_URL}"
	curl -fsSL "${RAW_URL}/aipod" -o "${DATA_DIR}/aipod"
	curl -fsSL "${RAW_URL}/Containerfile" -o "${DATA_DIR}/Containerfile"
	curl -fsSL "${RAW_URL}/aipod.conf.example" -o "${DATA_DIR}/aipod.conf.example"
}

main() {
	mkdir -p "${DATA_DIR}"
	mkdir -p "${CONFIG_DIR}"
	mkdir -p "${BIN_DIR}"

	if is_local_source; then
		install_from_local
	else
		install_from_remote
	fi

	chmod +x "${DATA_DIR}/aipod"

	rm -f "${BIN_DIR}/aipod"
	ln -s "${DATA_DIR}/aipod" "${BIN_DIR}/aipod"
	log_info "created symlink ${BIN_DIR}/aipod"

	# Create config from example if not exists
	if [ ! -f "${CONFIG_DIR}/aipod.conf" ] && [ -f "${DATA_DIR}/aipod.conf.example" ]; then
		cp "${DATA_DIR}/aipod.conf.example" "${CONFIG_DIR}/aipod.conf"
		log_info "created config at ${CONFIG_DIR}/aipod.conf"
	fi

	log_info "aipod installed successfully"

	case ":$PATH:" in
	*":$BIN_DIR:"*) ;;
	*)
		printf '\n'
		log_info "add %s to your PATH:" "$BIN_DIR"
		printf '    export PATH="%s:$PATH"\n' "$BIN_DIR"
		;;
	esac
}

main "$@"
