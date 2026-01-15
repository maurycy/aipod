#!/usr/bin/env bash

# Load bats helpers (paths relative to test file, not this helper)
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration - unique per test run
export TEST_HOSTNAME="aipod-test-$$"
export TEST_USERNAME="testuser"

# Paths set in setup_file after BATS_FILE_TMPDIR is available
TEST_CONFIG_DIR=""
TEST_DATA_DIR=""
AIPOD=""

setup_file() {
    TEST_CONFIG_DIR="${BATS_FILE_TMPDIR}/config"
    TEST_DATA_DIR="${BATS_FILE_TMPDIR}/data"
    AIPOD="${BATS_TEST_DIRNAME}/../aipod"

    # Export for child processes
    export TEST_CONFIG_DIR TEST_DATA_DIR AIPOD

    # Create directories
    mkdir -p "${TEST_CONFIG_DIR}/aipod"
    mkdir -p "${TEST_DATA_DIR}/aipod"

    # Create test config
    cat > "${TEST_DATA_DIR}/aipod/aipod.conf" <<EOF
HOSTNAME="${TEST_HOSTNAME}"
USERNAME="${TEST_USERNAME}"
EOF

    # Copy Containerfile to data dir
    cp "${BATS_TEST_DIRNAME}/../Containerfile" "${TEST_DATA_DIR}/aipod/"
}

teardown_file() {
    # Clean up test container and images
    podman rm -f "${TEST_HOSTNAME}" 2>/dev/null || true
    podman rmi "${TEST_HOSTNAME}" 2>/dev/null || true
    podman rmi "${TEST_HOSTNAME}:snapshot" 2>/dev/null || true
}

setup() {
    # Re-export paths (they're set in setup_file but we need them in each test)
    TEST_CONFIG_DIR="${BATS_FILE_TMPDIR}/config"
    TEST_DATA_DIR="${BATS_FILE_TMPDIR}/data"
    AIPOD="${BATS_TEST_DIRNAME}/../aipod"

    # Point aipod to test config via XDG dirs
    export XDG_CONFIG_HOME="${TEST_CONFIG_DIR}"
    export XDG_DATA_HOME="${TEST_DATA_DIR}"
}

teardown() {
    # Clean mounts and ports files between tests
    rm -f "${TEST_CONFIG_DIR}/aipod/mounts" 2>/dev/null || true
    rm -f "${TEST_CONFIG_DIR}/aipod/ports" 2>/dev/null || true
}

# Helper: ensure container is clean before test
ensure_clean() {
    podman rm -f "${TEST_HOSTNAME}" 2>/dev/null || true
}

# Helper: check if container exists
container_exists() {
    podman container exists "${TEST_HOSTNAME}" 2>/dev/null
}

# Helper: check if container is running
container_running() {
    [ "$(podman container inspect -f '{{.State.Running}}' "${TEST_HOSTNAME}" 2>/dev/null)" = "true" ]
}

# Helper: check if image exists
image_exists() {
    podman image exists "${TEST_HOSTNAME}" 2>/dev/null
}
