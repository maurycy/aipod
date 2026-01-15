#!/usr/bin/env bats

load 'test_helper/common'

setup() {
    # Call common setup
    TEST_CONFIG_DIR="${BATS_FILE_TMPDIR}/config"
    TEST_DATA_DIR="${BATS_FILE_TMPDIR}/data"
    AIPOD="${BATS_TEST_DIRNAME}/../aipod"
    export XDG_CONFIG_HOME="${TEST_CONFIG_DIR}"
    export XDG_DATA_HOME="${TEST_DATA_DIR}"

    # Ensure clean state
    ensure_clean
    rm -f "${TEST_CONFIG_DIR}/aipod/mounts" 2>/dev/null || true
}

@test "aipod mount current directory" {
    cd "${BATS_FILE_TMPDIR}"
    mkdir -p testdir
    cd testdir

    run "${AIPOD}" mount
    assert_success
    assert_output --partial "mounting"

    # Check mounts file exists and has entry
    assert [ -f "${TEST_CONFIG_DIR}/aipod/mounts" ]
    run cat "${TEST_CONFIG_DIR}/aipod/mounts"
    assert_output --partial "testdir"
}

@test "aipod mount specific path" {
    mkdir -p "${BATS_FILE_TMPDIR}/myproject"

    run "${AIPOD}" mount "${BATS_FILE_TMPDIR}/myproject"
    assert_success

    run cat "${TEST_CONFIG_DIR}/aipod/mounts"
    assert_output --partial "myproject"
}

@test "aipod mount with custom remote path" {
    mkdir -p "${BATS_FILE_TMPDIR}/source"

    run "${AIPOD}" mount "${BATS_FILE_TMPDIR}/source" "/custom/path"
    assert_success

    run cat "${TEST_CONFIG_DIR}/aipod/mounts"
    assert_output --partial "/custom/path"
}

@test "aipod mount rejects home directory" {
    run "${AIPOD}" mount "${HOME}"
    assert_failure
    assert_output --partial "bad idea"
}

@test "aipod mount duplicate is idempotent" {
    mkdir -p "${BATS_FILE_TMPDIR}/dupedir"

    run "${AIPOD}" mount "${BATS_FILE_TMPDIR}/dupedir"
    assert_success

    run "${AIPOD}" mount "${BATS_FILE_TMPDIR}/dupedir"
    assert_success
    assert_output --partial "already exists"

    # Should only have one entry
    run wc -l < "${TEST_CONFIG_DIR}/aipod/mounts"
    assert_output "1"
}

@test "aipod unmount removes specific mount" {
    mkdir -p "${BATS_FILE_TMPDIR}/dir1"
    mkdir -p "${BATS_FILE_TMPDIR}/dir2"

    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/dir1"
    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/dir2"

    run "${AIPOD}" unmount "${BATS_FILE_TMPDIR}/dir1"
    assert_success

    run cat "${TEST_CONFIG_DIR}/aipod/mounts"
    refute_output --partial "dir1"
    assert_output --partial "dir2"
}

@test "aipod unmount removes all mounts" {
    mkdir -p "${BATS_FILE_TMPDIR}/a"
    mkdir -p "${BATS_FILE_TMPDIR}/b"

    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/a"
    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/b"

    run "${AIPOD}" unmount
    assert_success
    assert_output --partial "removing all mounts"

    assert [ ! -f "${TEST_CONFIG_DIR}/aipod/mounts" ]
}

@test "aipod umount alias works" {
    mkdir -p "${BATS_FILE_TMPDIR}/aliasdir"
    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/aliasdir"

    run "${AIPOD}" umount
    assert_success
    assert [ ! -f "${TEST_CONFIG_DIR}/aipod/mounts" ]
}

@test "aipod status shows mounts" {
    mkdir -p "${BATS_FILE_TMPDIR}/visible"
    "${AIPOD}" mount "${BATS_FILE_TMPDIR}/visible"

    run "${AIPOD}" status
    assert_success
    assert_output --partial "mounts:"
    assert_output --partial "visible"
}
