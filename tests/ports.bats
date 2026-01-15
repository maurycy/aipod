#!/usr/bin/env bats

load 'test_helper/common'

setup() {
    TEST_CONFIG_DIR="${BATS_FILE_TMPDIR}/config"
    TEST_DATA_DIR="${BATS_FILE_TMPDIR}/data"
    AIPOD="${BATS_TEST_DIRNAME}/../aipod"
    export XDG_CONFIG_HOME="${TEST_CONFIG_DIR}"
    export XDG_DATA_HOME="${TEST_DATA_DIR}"

    ensure_clean
    rm -f "${TEST_CONFIG_DIR}/aipod/ports" 2>/dev/null || true
}

@test "aipod port exposes port" {
    run "${AIPOD}" port 8080
    assert_success
    assert_output --partial "exposing port 8080"

    assert [ -f "${TEST_CONFIG_DIR}/aipod/ports" ]
    run cat "${TEST_CONFIG_DIR}/aipod/ports"
    assert_output "8080:8080"
}

@test "aipod port with custom host port" {
    run "${AIPOD}" port 3000 9000
    assert_success
    assert_output --partial "exposing port 3000 to host port 9000"

    run cat "${TEST_CONFIG_DIR}/aipod/ports"
    assert_output "9000:3000"
}

@test "aipod port validates container port" {
    run "${AIPOD}" port 0
    assert_failure
    assert_output --partial "invalid container port"

    run "${AIPOD}" port 70000
    assert_failure
    assert_output --partial "invalid container port"

    run "${AIPOD}" port abc
    assert_failure
    assert_output --partial "invalid container port"
}

@test "aipod port validates host port" {
    run "${AIPOD}" port 8080 0
    assert_failure
    assert_output --partial "invalid host port"

    run "${AIPOD}" port 8080 99999
    assert_failure
    assert_output --partial "invalid host port"
}

@test "aipod port duplicate is idempotent" {
    run "${AIPOD}" port 5000
    assert_success

    run "${AIPOD}" port 5000
    assert_success
    assert_output --partial "already exposed"

    run wc -l < "${TEST_CONFIG_DIR}/aipod/ports"
    assert_output "1"
}

@test "aipod port requires port argument" {
    run "${AIPOD}" port
    assert_failure
    assert_output --partial "usage:"
}

@test "aipod close removes specific port" {
    "${AIPOD}" port 8080
    "${AIPOD}" port 9090

    run "${AIPOD}" close 8080
    assert_success

    run cat "${TEST_CONFIG_DIR}/aipod/ports"
    refute_output --partial "8080"
    assert_output --partial "9090"
}

@test "aipod close removes all ports" {
    "${AIPOD}" port 1111
    "${AIPOD}" port 2222

    run "${AIPOD}" close
    assert_success
    assert_output --partial "removing all port mappings"

    assert [ ! -f "${TEST_CONFIG_DIR}/aipod/ports" ]
}

@test "aipod expose alias works" {
    run "${AIPOD}" expose 7777
    assert_success
    assert_output --partial "exposing port 7777"
}

@test "aipod bind alias works" {
    run "${AIPOD}" bind 6666
    assert_success
    assert_output --partial "exposing port 6666"
}

@test "aipod unbind alias works" {
    "${AIPOD}" port 4444

    run "${AIPOD}" unbind 4444
    assert_success
}

@test "aipod status shows ports" {
    "${AIPOD}" port 8888

    run "${AIPOD}" status
    assert_success
    assert_output --partial "ports:"
    assert_output --partial "8888"
}
