#!/usr/bin/env bats

load 'test_helper/common'

@test "aipod help shows usage" {
    run "${AIPOD}" help
    assert_success
    assert_output --partial "aipod: manage development container"
    assert_output --partial "Commands:"
}

@test "aipod --help shows usage" {
    run "${AIPOD}" --help
    assert_success
    assert_output --partial "aipod: manage development container"
}

@test "aipod unknown command fails" {
    run "${AIPOD}" notacommand
    assert_failure
    assert_output --partial "unknown command: notacommand"
}

@test "aipod status shows not created initially" {
    ensure_clean
    run "${AIPOD}" status
    assert_success
    assert_output --partial "container: not created"
}

@test "aipod up creates and starts container" {
    ensure_clean
    run "${AIPOD}" up </dev/null &
    pid=$!
    # Give it time to start the container
    sleep 5
    kill $pid 2>/dev/null || true

    assert container_exists
    assert container_running
}

@test "aipod status shows running after up" {
    run "${AIPOD}" status
    assert_success
    assert_output --partial "container: running"
    assert_output --partial "image:     ${TEST_HOSTNAME}"
}

@test "aipod down stops container" {
    run "${AIPOD}" down
    assert_success
    assert_output --partial "stopping container"

    assert container_exists
    refute container_running
}

@test "aipod status shows stopped after down" {
    run "${AIPOD}" status
    assert_success
    assert_output --partial "container: stopped"
}

@test "aipod start alias works" {
    run "${AIPOD}" start </dev/null &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null || true

    assert container_running
}

@test "aipod stop alias works" {
    run "${AIPOD}" stop
    assert_success
    refute container_running
}

@test "aipod clean removes container and image" {
    # First ensure container exists
    run "${AIPOD}" start </dev/null &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null || true

    run "${AIPOD}" clean
    assert_success
    assert_output --partial "removing container"
    assert_output --partial "removing image"

    refute container_exists
    refute image_exists
}

@test "aipod purge alias works" {
    # Build first
    run "${AIPOD}" start </dev/null &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null || true

    run "${AIPOD}" purge
    assert_success
    refute container_exists
}
