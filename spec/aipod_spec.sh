# shellcheck shell=sh disable=SC2317

Describe 'aipod'
	REAL_PODMAN="$(command -v podman)"
	if [ -n "${XDG_CONFIG_HOME:-}" ]; then
		ORIGINAL_XDG_CONFIG_HOME_SET="true"
		ORIGINAL_XDG_CONFIG_HOME="${XDG_CONFIG_HOME}"
	else
		ORIGINAL_XDG_CONFIG_HOME_SET="false"
		ORIGINAL_XDG_CONFIG_HOME=""
	fi
	FIXTURE_CONTAINERFILE="${SHELLSPEC_PROJECT_ROOT}/spec/fixtures/Containerfile"

	write_conf() {
		cat > "${TEST_ROOT}/aipod.conf" <<-EOF
			HOSTNAME=${AIPOD_NAME}
			USERNAME=developer
			CONTAINERFILE=${FIXTURE_CONTAINERFILE}
			CHEZMOI_DOTFILES_REPO=

			USE_RUST=false
			USE_NPM=false
			USE_UV=false
			USE_CLAUDE_CODE=false
			USE_CODEX=false
			USE_COPILOT=false
			USE_PI=false
			USE_AGY=false
			USE_MISE=false
			USE_OVERMIND=false
			USE_JUST=false

			CAP_ADD=
		EOF
	}

	setup() {
		TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/aipod-shellspec.XXXXXX")"
		TEST_ROOT="$(cd "${TEST_ROOT}" && pwd)"
		test_id="$(printf '%s' "${TEST_ROOT}" | cksum | awk '{print $1}')"
		AIPOD_NAME="aipod-test-${test_id}"
		HOST_PORT="$((40000 + test_id % 20000))"

		[ -f "${FIXTURE_CONTAINERFILE}" ] || return 1
		case "${FIXTURE_CONTAINERFILE}" in
			/*) ;;
			*) return 1 ;;
		esac

		if "${REAL_PODMAN}" container exists "${AIPOD_NAME}" 2>/dev/null; then
			echo "refusing to reuse existing container ${AIPOD_NAME}" >&2
			return 1
		fi

		mkdir -p \
			"${TEST_ROOT}/bin" \
			"${TEST_ROOT}/xdg/aipod" \
			"${TEST_ROOT}/workspace/subdir" \
			"${TEST_ROOT}/copy-source" \
			"${TEST_ROOT}/copy-destination"

		AIPOD="${TEST_ROOT}/aipod"
		AIPOD_CONFIG_DIR="${TEST_ROOT}/xdg/aipod"
		MOUNTS_FILE="${AIPOD_CONFIG_DIR}/mounts"
		PORTS_FILE="${AIPOD_CONFIG_DIR}/ports"
		WORKSPACE="${TEST_ROOT}/workspace"
		COPY_SOURCE="${TEST_ROOT}/copy-source"
		COPY_DESTINATION="${TEST_ROOT}/copy-destination"

		cp "${SHELLSPEC_PROJECT_ROOT}/aipod" "${AIPOD}"
		chmod +x "${AIPOD}"
		write_conf

		cp "${SHELLSPEC_PROJECT_ROOT}/spec/support/podman-wrapper" "${TEST_ROOT}/bin/podman"
		chmod +x "${TEST_ROOT}/bin/podman"

		AIPOD_TEST_REAL_PODMAN="${REAL_PODMAN}"
		AIPOD_TEST_PODMAN_XDG_CONFIG_HOME_SET="${ORIGINAL_XDG_CONFIG_HOME_SET}"
		AIPOD_TEST_PODMAN_XDG_CONFIG_HOME="${ORIGINAL_XDG_CONFIG_HOME}"
		export AIPOD_TEST_REAL_PODMAN
		export AIPOD_TEST_PODMAN_XDG_CONFIG_HOME_SET
		export AIPOD_TEST_PODMAN_XDG_CONFIG_HOME

		PATH="${TEST_ROOT}/bin:${PATH}"
		export PATH

		XDG_CONFIG_HOME="${TEST_ROOT}/xdg"
		export XDG_CONFIG_HOME
	}

	cleanup() {
		if [ -n "${AIPOD_NAME:-}" ] && [ -x "${TEST_ROOT}/bin/podman" ]; then
			"${TEST_ROOT}/bin/podman" rm -f --time 0 "${AIPOD_NAME}" >/dev/null 2>&1 || :
			"${TEST_ROOT}/bin/podman" rmi -f "${AIPOD_NAME}:snapshot" >/dev/null 2>&1 || :
			"${TEST_ROOT}/bin/podman" rmi -f "${AIPOD_NAME}" >/dev/null 2>&1 || :
		fi
		case "${TEST_ROOT:-}" in
			*/aipod-shellspec.??????)
				[ "${TEST_ROOT}" = "/" ] && return 0
				[ "${TEST_ROOT}" = "${HOME}" ] && return 0
				[ "${TEST_ROOT}" = "${SHELLSPEC_PROJECT_ROOT}" ] && return 0
				rm -rf "${TEST_ROOT}"
				;;
		esac
	}

	BeforeEach 'setup'
	AfterEach 'cleanup'

	run_aipod() { "${AIPOD}" "$@"; }
	container_present() { podman container exists "${AIPOD_NAME}"; }
	container_absent() { ! podman container exists "${AIPOD_NAME}"; }
	image_present() { podman image exists "${AIPOD_NAME}"; }
	image_absent() { ! podman image exists "${AIPOD_NAME}"; }
	snapshot_present() { podman image exists "${AIPOD_NAME}:snapshot"; }
	snapshot_absent() { ! podman image exists "${AIPOD_NAME}:snapshot"; }

	inspect_running() {
		podman container inspect --format '{{.State.Running}}' "${AIPOD_NAME}"
	}
	inspect_hostname() {
		podman container inspect --format '{{.Config.Hostname}}' "${AIPOD_NAME}"
	}
	inspect_mount_source() {
		podman container inspect --format \
			"{{range .Mounts}}{{if eq .Destination \"$1\"}}{{.Source}}{{end}}{{end}}" \
			"${AIPOD_NAME}"
	}
	inspect_capabilities() {
		podman container inspect --format '{{.HostConfig.CapAdd}}' "${AIPOD_NAME}"
	}

	running_is() { [ "$(inspect_running)" = "$1" ]; }
	hostname_is() { [ "$(inspect_hostname)" = "$1" ]; }
	has_capability() { inspect_capabilities | grep -q "$1"; }
	mount_dest_absent() { [ -z "$(inspect_mount_source "$1")" ]; }
	mount_source_is_workspace() {
		[ "$(inspect_mount_source /workspace)" = "$(cd "${WORKSPACE}" && pwd)" ]
	}
	image_is_fixture() {
		[ "$(podman image inspect --format \
			'{{index .Labels "org.aipod.test-fixture"}}' "${AIPOD_NAME}")" = "true" ]
	}
	mounts_lines_eq() { [ "$(wc -l < "${MOUNTS_FILE}")" -eq "$1" ]; }
	mounts_line_is() { [ "$(cat "${MOUNTS_FILE}")" = "$1" ]; }
	ports_line_is() { [ "$(cat "${PORTS_FILE}")" = "$1" ]; }

	Describe 'lifecycle' podman
		It 'reports nothing created before first use'
			When call run_aipod status
			The status should be success
			The output should include 'container: not created'
			The output should include 'image:     not built'
			The output should include 'snapshot:  (none)'
			The output should include '(none)'
			Assert container_absent
			Assert image_absent
		End

		It 'creates a running container on first run'
			When call run_aipod run true
			The status should be success
			The output should be present
			The stderr should include "building image ${AIPOD_NAME}"
			The stderr should include "creating container ${AIPOD_NAME}"
			Assert container_present
			Assert image_present
			Assert running_is true
			Assert hostname_is "${AIPOD_NAME}"
		End

		It 'opens a shell after starting the container'
			When call run_aipod up
			The status should be success
			The output should be present
			The stderr should include "creating container ${AIPOD_NAME}"
			The stderr should include "opening shell in running container ${AIPOD_NAME}"
			Assert container_present
			Assert running_is true
		End

		It 'stops but does not remove the container on down'
			lifecycle_down() {
				run_aipod run true >/dev/null 2>&1 &&
					run_aipod down >/dev/null 2>&1 &&
					run_aipod status
			}
			When call lifecycle_down
			The status should be success
			The output should include 'container: stopped'
			Assert container_present
			Assert running_is false
			Assert image_present
		End

		It 'restarts a stopped container without rebuilding'
			lifecycle_restart() {
				run_aipod run true >/dev/null 2>&1 &&
					run_aipod down >/dev/null 2>&1 &&
					run_aipod run true
			}
			When call lifecycle_restart
			The status should be success
			The stderr should include 'starting container'
			The stderr should not include 'building image'
			Assert running_is true
		End

		It 'removes only its own resources on clean'
			lifecycle_clean() {
				run_aipod run true >/dev/null 2>&1 &&
					run_aipod map "${WORKSPACE}" /workspace >/dev/null 2>&1 &&
					run_aipod port 8080 "${HOST_PORT}" >/dev/null 2>&1 &&
					touch "${TEST_ROOT}/control-file" &&
					run_aipod clean
			}
			When call lifecycle_clean
			The status should be success
			The output should be present
			The stderr should include "removing container ${AIPOD_NAME}"
			Assert container_absent
			Assert image_absent
			Assert snapshot_absent
			The path "${MOUNTS_FILE}" should not be exist
			The path "${PORTS_FILE}" should not be exist
			The path "${TEST_ROOT}/control-file" should be exist
			The path "${TEST_ROOT}" should be exist
		End
	End

	Describe 'configuration precedence' podman
		It 'prefers the config next to the script over XDG'
			config_precedence() {
				cat > "${AIPOD_CONFIG_DIR}/aipod.conf" <<-EOF
					HOSTNAME=${AIPOD_NAME}-xdg
					CONTAINERFILE=${FIXTURE_CONTAINERFILE}
				EOF
				run_aipod run true
			}
			xdg_container_absent() { ! podman container exists "${AIPOD_NAME}-xdg"; }
			When call config_precedence
			The status should be success
			The output should be present
			The stderr should include "creating container ${AIPOD_NAME}"
			Assert container_present
			Assert xdg_container_absent
			Assert hostname_is "${AIPOD_NAME}"
			Assert image_is_fixture
		End
	End

	Describe 'capabilities' podman
		It 'adds configured capabilities to the container'
			cap_add_run() {
				printf 'CAP_ADD="NET_RAW SYS_PTRACE"\n' >> "${TEST_ROOT}/aipod.conf"
				run_aipod run true
			}
			When call cap_add_run
			The status should be success
			The output should be present
			The stderr should include "creating container ${AIPOD_NAME}"
			Assert has_capability CAP_NET_RAW
			Assert has_capability CAP_SYS_PTRACE
		End
	End

	Describe 'mounts' podman
		It 'maps a directory before the container exists'
			mount_before_create() {
				run_aipod map "${WORKSPACE}" /workspace >/dev/null 2>&1 &&
					cd "${WORKSPACE}/subdir" &&
					run_aipod run pwd
			}
			When call mount_before_create
			The status should be success
			The stderr should include "creating container ${AIPOD_NAME}"
			The output should include '/workspace/subdir'
			Assert mounts_lines_eq 1
			Assert running_is true
			Assert mount_source_is_workspace
		End

		It 'ignores a duplicate mount of the same source and destination'
			duplicate_mount() {
				run_aipod map "${WORKSPACE}" /workspace >/dev/null 2>&1 &&
					run_aipod map "${WORKSPACE}" /workspace
			}
			When call duplicate_mount
			The status should be success
			The stderr should include 'already exists'
			Assert mounts_lines_eq 1
		End

		It 'rejects a second source for an already mounted destination'
			conflicting_mount() {
				run_aipod map "${WORKSPACE}" /workspace >/dev/null 2>&1 || return 1
				run_aipod map "${COPY_SOURCE}" /workspace
			}
			When call conflicting_mount
			The status should eq 1
			The stderr should include 'destination /workspace is already mounted from another path'
			Assert mounts_lines_eq 1
			Assert mounts_line_is "${WORKSPACE}:/workspace"
		End

		It 'recreates the container headlessly after map and keeps state'
			recreate_after_map() {
				run_aipod run 'printf preserved > /home/developer/sentinel' >/dev/null 2>&1 &&
					run_aipod map "${WORKSPACE}" /workspace >/dev/null 2>&1 &&
					run_aipod run 'cat /home/developer/sentinel'
			}
			When call recreate_after_map
			The status should be success
			The output should eq 'preserved'
			Assert snapshot_present
			Assert running_is true
			Assert mount_source_is_workspace
		End

		It 'recreates the container headlessly after unmap and keeps state'
			recreate_after_unmap() {
				run_aipod map "${WORKSPACE}" /workspace >/dev/null 2>&1 &&
					run_aipod run 'printf preserved > /home/developer/sentinel' >/dev/null 2>&1 &&
					run_aipod unmap "${WORKSPACE}" >/dev/null 2>&1 &&
					run_aipod run 'cat /home/developer/sentinel'
			}
			When call recreate_after_unmap
			The status should be success
			The output should eq 'preserved'
			Assert running_is true
			Assert mount_dest_absent /workspace
			The path "${MOUNTS_FILE}" should not be exist
		End
	End

	Describe 'port validation' podman
		It 'rejects a missing port argument'
			When call run_aipod port
			The status should eq 1
			The stderr should include 'usage'
		End

		Describe 'invalid values'
			Parameters
				0
				abc
				65536
			End

			It "rejects port $1"
				When call run_aipod port "$1"
				The status should eq 1
				The stderr should include 'invalid'
				The path "${PORTS_FILE}" should not be exist
			End
		End

		Describe 'valid values'
			Parameters
				1
				65535
			End

			It "accepts port $1"
				When call run_aipod port "$1"
				The status should be success
				The stderr should include "exposing port $1"
				Assert ports_line_is "$1:$1"
				Assert container_absent
			End
		End
	End

	Describe 'ports' podman
		It 'publishes a configured port on the host'
			port_mapping() {
				run_aipod port 8080 "${HOST_PORT}" >/dev/null 2>&1 &&
					run_aipod run true >/dev/null 2>&1 &&
					podman port "${AIPOD_NAME}" 8080/tcp
			}
			When call port_mapping
			The status should be success
			The output should include ":${HOST_PORT}"
			Assert ports_line_is "${HOST_PORT}:8080"
			Assert running_is true
		End

		It 'recreates the container headlessly after port and close'
			port_close_sequence() {
				run_aipod run 'printf preserved > /home/developer/sentinel' >/dev/null 2>&1 || return 1
				run_aipod port 8080 "${HOST_PORT}" >/dev/null 2>&1 || return 1
				snapshot_present && printf 'snapshot-after-port\n'
				mapped="$(podman port "${AIPOD_NAME}" 8080/tcp 2>/dev/null)" || mapped=""
				[ -n "${mapped}" ] && printf 'port-mapped\n'
				run_aipod close 8080 >/dev/null 2>&1 || return 1
				mapped="$(podman port "${AIPOD_NAME}" 8080/tcp 2>/dev/null)" || mapped=""
				[ -z "${mapped}" ] && printf 'port-closed\n'
				run_aipod run 'cat /home/developer/sentinel'
			}
			When call port_close_sequence
			The status should be success
			The output should include 'snapshot-after-port'
			The output should include 'port-mapped'
			The output should include 'port-closed'
			The output should include 'preserved'
			Assert running_is true
			The path "${PORTS_FILE}" should not be exist
		End
	End

	Describe 'run' podman
		It 'runs a command without a TTY'
			plain_run() {
				run_aipod run true </dev/null >/dev/null 2>&1 || return 1
				run_aipod run 'printf "ok\n"'
			}
			When call plain_run
			The status should be success
			The output should eq 'ok'
		End

		It 'passes piped stdin to the command'
			piped_run() {
				run_aipod run true </dev/null >/dev/null 2>&1 || return 1
				run_aipod run 'read value; printf "%s\n" "$value"'
			}
			Data 'hello-from-stdin'
			When call piped_run
			The status should be success
			The output should eq 'hello-from-stdin'
		End

		It 'propagates the command exit status'
			failing_run() {
				run_aipod run true </dev/null >/dev/null 2>&1 || return 1
				run_aipod run 'exit 17'
			}
			When call failing_run
			The status should eq 17
		End
	End

	Describe 'cp' podman
		It 'copies a file from host to container'
			cp_to_container() {
				printf 'input-content\n' > "${COPY_SOURCE}/input.txt" || return 1
				run_aipod cp "${COPY_SOURCE}/input.txt" >/dev/null 2>&1 || return 1
				run_aipod run 'cat /home/developer/input.txt'
			}
			When call cp_to_container
			The status should be success
			The output should eq 'input-content'
		End

		It 'copies a file from container to host'
			cp_from_container() {
				run_aipod run 'printf output-content > /home/developer/output.txt' >/dev/null 2>&1 || return 1
				run_aipod cp :/home/developer/output.txt "${COPY_DESTINATION}" >/dev/null 2>&1 || return 1
				cat "${COPY_DESTINATION}/output.txt"
			}
			When call cp_from_container
			The status should be success
			The output should eq 'output-content'
		End
	End

	Describe 'with a mocked podman' mock
		install_mock_podman() {
			mkdir -p "${TEST_ROOT}/mockbin"
			cat > "${TEST_ROOT}/mockbin/podman" <<-'EOF'
				#!/bin/sh
				if [ -n "${AIPOD_TEST_MOCK_LOG:-}" ]; then
					printf '%s\n' "$*" >> "${AIPOD_TEST_MOCK_LOG}"
				fi
				scenario="${AIPOD_TEST_MOCK_SCENARIO:-}"
				case "${1:-} ${2:-}" in
					'container exists' | 'image exists')
						case "${scenario}" in
							running | not-running | start-failure) exit 0 ;;
						esac
						exit 1
						;;
					'container inspect')
						if [ "${scenario}" = "running" ]; then
							printf 'true\n'
						else
							printf 'false\n'
						fi
						exit 0
						;;
				esac
				case "${1:-}" in
					build)
						[ "${scenario}" = "build-failure" ] && exit 1
						exit 0
						;;
					start)
						[ "${scenario}" = "start-failure" ] && exit 1
						exit 0
						;;
				esac
				exit 0
			EOF
			chmod +x "${TEST_ROOT}/mockbin/podman"
			PATH="${TEST_ROOT}/mockbin:${PATH}"
			export PATH
		}

		mock_log_has() { grep -q "$1" "${TEST_ROOT}/podman.log"; }
		mock_log_lacks() { ! grep -q "$1" "${TEST_ROOT}/podman.log"; }

		It 'allocates a TTY when all streams are terminals'
			tty_exec() {
				install_mock_podman
				AIPOD_TEST_MOCK_LOG="${TEST_ROOT}/podman.log"
				AIPOD_TEST_MOCK_SCENARIO="running"
				export AIPOD AIPOD_TEST_MOCK_LOG AIPOD_TEST_MOCK_SCENARIO
				case "$(uname -s)" in
					Darwin) script -q /dev/null "${AIPOD}" up ;;
					*) script -q -e -c '"${AIPOD}" up' /dev/null ;;
				esac
			}
			When call tty_exec
			The status should be success
			The output should be present
			Assert mock_log_has "exec -it ${AIPOD_NAME} /bin/zsh"
		End

		Describe 'with one redirected stream'
			Parameters
				stdin
				stdout
				stderr
			End

			It "does not allocate a TTY when $1 is redirected"
				redirected_exec() {
					install_mock_podman
					AIPOD_TEST_MOCK_LOG="${TEST_ROOT}/podman.log"
					AIPOD_TEST_MOCK_SCENARIO="running"
					export AIPOD AIPOD_TEST_MOCK_LOG AIPOD_TEST_MOCK_SCENARIO TEST_ROOT
					case "$1" in
						stdin) tty_command='"${AIPOD}" up </dev/null' ;;
						stdout) tty_command='"${AIPOD}" up >"${TEST_ROOT}/stdout"' ;;
						stderr) tty_command='"${AIPOD}" up 2>"${TEST_ROOT}/stderr"' ;;
					esac
					case "$(uname -s)" in
						Darwin) script -q /dev/null /bin/sh -c "${tty_command}" >/dev/null ;;
						*) script -q -e -c "${tty_command}" /dev/null >/dev/null ;;
					esac
				}
				When call redirected_exec "$1"
				The status should be success
				Assert mock_log_has "exec -i ${AIPOD_NAME} /bin/zsh"
				Assert mock_log_lacks "exec -it ${AIPOD_NAME} /bin/zsh"
			End
		End

		It 'fails clearly when podman is missing'
			run_without_podman() {
				mkdir -p "${TEST_ROOT}/emptybin"
				env PATH="${TEST_ROOT}/emptybin" "${AIPOD}" status
			}
			When call run_without_podman
			The status should eq 1
			The stderr should include 'podman is not installed'
		End

		It 'does not leak the host HOSTNAME into the container name'
			hostname_leak() {
				install_mock_podman
				AIPOD_TEST_MOCK_LOG="${TEST_ROOT}/podman.log"
				export AIPOD_TEST_MOCK_LOG
				cat > "${TEST_ROOT}/aipod.conf" <<-EOF
					USERNAME=developer
					CONTAINERFILE=${FIXTURE_CONTAINERFILE}
				EOF
				env HOSTNAME=leaked-host "${AIPOD}" status
			}
			When call hostname_leak
			The status should be success
			The output should include 'container: not created'
			Assert mock_log_has 'container exists aipod'
			Assert mock_log_lacks 'leaked-host'
		End

		It 'propagates a podman build failure'
			failing_build() {
				install_mock_podman
				AIPOD_TEST_MOCK_SCENARIO="build-failure"
				export AIPOD_TEST_MOCK_SCENARIO
				run_aipod run true
			}
			When call failing_build
			The status should eq 1
			The stderr should include "building image ${AIPOD_NAME}"
		End

		It 'reports an error when a created container does not remain running'
			created_container_stops() {
				install_mock_podman
				AIPOD_TEST_MOCK_LOG="${TEST_ROOT}/podman.log"
				export AIPOD_TEST_MOCK_LOG
				run_aipod run true
			}
			When call created_container_stops
			The status should eq 1
			The stderr should include "container ${AIPOD_NAME} is not running"
			Assert mock_log_has 'run -d --replace --init'
		End

		It 'propagates a podman start failure'
			failing_start() {
				install_mock_podman
				AIPOD_TEST_MOCK_SCENARIO="start-failure"
				export AIPOD_TEST_MOCK_SCENARIO
				run_aipod run true
			}
			When call failing_start
			The status should eq 1
			The stderr should include "failed to start container ${AIPOD_NAME}"
		End

		It 'reports an error when the container never reaches running state'
			stuck_container() {
				install_mock_podman
				AIPOD_TEST_MOCK_SCENARIO="not-running"
				export AIPOD_TEST_MOCK_SCENARIO
				run_aipod run true
			}
			When call stuck_container
			The status should eq 1
			The stderr should include "container ${AIPOD_NAME} is not running"
		End
	End
End
