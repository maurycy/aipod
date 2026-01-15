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

@test "aipod cp requires path argument" {
    run "${AIPOD}" cp
    assert_failure
    assert_output --partial "usage:"
}

@test "aipod cp fails on nonexistent path" {
    run "${AIPOD}" cp /nonexistent/path
    assert_failure
    assert_output --partial "does not exist"
}

@test "aipod cp copies file to container" {
    # Ensure container is running
    "${AIPOD}" start </dev/null &
    pid=$!
    sleep 3
    kill $pid 2>/dev/null || true

    # Create test file
    echo "test content" > "${BATS_FILE_TMPDIR}/testfile.txt"

    run "${AIPOD}" cp "${BATS_FILE_TMPDIR}/testfile.txt"
    assert_success
    assert_output --partial "syncing"

    # Verify file exists in container
    run podman exec "${TEST_HOSTNAME}" cat "/home/${TEST_USERNAME}/testfile.txt"
    assert_success
    assert_output "test content"
}

@test "aipod cp copies directory to container" {
    "${AIPOD}" start </dev/null &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null || true

    # Create test directory with files
    mkdir -p "${BATS_FILE_TMPDIR}/testdir"
    echo "file1" > "${BATS_FILE_TMPDIR}/testdir/a.txt"
    echo "file2" > "${BATS_FILE_TMPDIR}/testdir/b.txt"

    run "${AIPOD}" cp "${BATS_FILE_TMPDIR}/testdir"
    assert_success

    # Verify directory exists in container
    run podman exec "${TEST_HOSTNAME}" ls "/home/${TEST_USERNAME}/testdir/"
    assert_success
    assert_output --partial "a.txt"
    assert_output --partial "b.txt"
}

@test "aipod sync alias works" {
    "${AIPOD}" start </dev/null &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null || true

    echo "sync test" > "${BATS_FILE_TMPDIR}/syncfile.txt"

    run "${AIPOD}" sync "${BATS_FILE_TMPDIR}/syncfile.txt"
    assert_success
    assert_output --partial "syncing"
}

@test "aipod cp uses mount path when available" {
    # Create and mount a directory
    mkdir -p "${BATS_FILE_TMPDIR}/mounted"
    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/mounted"

    "${AIPOD}" start </dev/null &
    pid=$!
    sleep 3
    kill $pid 2>/dev/null || true

    # Create file inside mounted directory
    echo "mounted content" > "${BATS_FILE_TMPDIR}/mounted/inner.txt"

    run "${AIPOD}" cp "${BATS_FILE_TMPDIR}/mounted/inner.txt"
    assert_success
    # Should use the mount path
    assert_output --partial "/home/${TEST_USERNAME}/mounted/inner.txt"
}
