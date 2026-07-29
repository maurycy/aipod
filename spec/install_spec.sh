# shellcheck shell=sh disable=SC2317

Describe 'install.sh' install
	setup() {
		INSTALL_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/aipod-shellspec.XXXXXX")"
		INSTALL_ROOT="$(cd "${INSTALL_ROOT}" && pwd)"

		HOME="${INSTALL_ROOT}/home"
		XDG_CONFIG_HOME="${INSTALL_ROOT}/config"
		XDG_DATA_HOME="${INSTALL_ROOT}/data"
		export HOME XDG_CONFIG_HOME XDG_DATA_HOME
		mkdir -p "${HOME}"

		SOURCE_DIR="${INSTALL_ROOT}/source"
		mkdir -p "${SOURCE_DIR}"
		cp "${SHELLSPEC_PROJECT_ROOT}/install.sh" \
			"${SHELLSPEC_PROJECT_ROOT}/aipod" \
			"${SHELLSPEC_PROJECT_ROOT}/Containerfile" \
			"${SHELLSPEC_PROJECT_ROOT}/aipod.conf.example" \
			"${SOURCE_DIR}/"

		INSTALLED_AIPOD="${XDG_DATA_HOME}/aipod/aipod"
		INSTALLED_CONF="${XDG_CONFIG_HOME}/aipod/aipod.conf"
	}

	cleanup() {
		case "${INSTALL_ROOT:-}" in
			*/aipod-shellspec.??????)
				rm -rf "${INSTALL_ROOT}"
				;;
		esac
	}

	BeforeEach 'setup'
	AfterEach 'cleanup'

	run_install() { sh "${SOURCE_DIR}/install.sh"; }
	symlink_points_to_installed() {
		[ "$(readlink "${HOME}/.local/bin/aipod")" = "${INSTALLED_AIPOD}" ]
	}
	conf_has_marker() { grep -q 'custom-marker' "${INSTALLED_CONF}"; }

	It 'installs from local source'
		When call run_install
		The status should be success
		The output should include 'aipod installed successfully'
		The path "${INSTALLED_AIPOD}" should be exist
		The path "${INSTALLED_AIPOD}" should be executable
		The path "${XDG_DATA_HOME}/aipod/Containerfile" should be exist
		The path "${XDG_DATA_HOME}/aipod/aipod.conf.example" should be exist
		The path "${HOME}/.local/bin/aipod" should be symlink
		The path "${INSTALLED_CONF}" should be exist
		Assert symlink_points_to_installed
	End

	It 'is idempotent and preserves an edited config'
		reinstall() {
			sh "${SOURCE_DIR}/install.sh" >/dev/null 2>&1 || return 1
			printf '# custom-marker\n' >> "${INSTALLED_CONF}" || return 1
			sh "${SOURCE_DIR}/install.sh"
		}
		When call reinstall
		The status should be success
		The output should include 'aipod installed successfully'
		Assert conf_has_marker
		Assert symlink_points_to_installed
	End
End
