#!/usr/bin/env bats

load 'test_helper/common'

setup() {
    TEST_CONFIG_DIR="${BATS_FILE_TMPDIR}/config"
    TEST_DATA_DIR="${BATS_FILE_TMPDIR}/data"
    AIPOD="${BATS_TEST_DIRNAME}/../aipod"
    export XDG_CONFIG_HOME="${TEST_CONFIG_DIR}"
    export XDG_DATA_HOME="${TEST_DATA_DIR}"

    rm -f "${TEST_CONFIG_DIR}/aipod/mounts" 2>/dev/null || true
}

@test "aipod run requires command" {
    run "${AIPOD}" run
    assert_failure
    assert_output --partial "usage:"
}

@test "aipod run executes command in container" {
    # Ensure container is running first
    "${AIPOD}" start </dev/null &
    pid=$!
    sleep 3
    kill $pid 2>/dev/null || true

    run "${AIPOD}" run echo hello
    assert_success
    assert_output --partial "hello"
}

@test "aipod run with arguments" {
    "${AIPOD}" start </dev/null &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null || true

    run "${AIPOD}" run echo one two three
    assert_success
    assert_output --partial "one two three"
}

@test "aipod run translates CWD when mounted" {
    # Create a test directory and mount it
    mkdir -p "${BATS_FILE_TMPDIR}/workdir"
    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/workdir"

    # Start container with mount
    "${AIPOD}" start </dev/null &
    pid=$!
    sleep 3
    kill $pid 2>/dev/null || true

    # Run from mounted directory
    cd "${BATS_FILE_TMPDIR}/workdir"
    run "${AIPOD}" run pwd
    assert_success
    assert_output --partial "/home/${TEST_USERNAME}/workdir"
}

@test "aipod run starts container if not running" {
    ensure_clean

    # This should auto-start the container
    run "${AIPOD}" run echo autostart
    assert_success
    assert_output --partial "autostart"
}
