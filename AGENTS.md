# AGENTS.md

aipod is a single POSIX sh script managing a podman dev container.

- `#!/bin/sh`, no bashisms; macOS /bin/sh is bash-as-sh and pre-sets variables
  like `HOSTNAME` - give config variables explicit defaults.
- `shellcheck aipod install.sh spec/support/podman-wrapper` must pass (CI).
- Tests: `shellspec` (CI); most tests need a running podman. Each test copies
  `aipod` + a generated `aipod.conf` to a scratch dir (script dir beats XDG),
  uses an absolute fixture `CONTAINERFILE`, names resources
  `aipod-test-<id>` - never `aipod` - and asserts engine state with
  `podman inspect`.
- Commits: `feat:`/`fix:`/`chore:`, variable names in backticks.
- PR descriptions are extremely minimal: a few one-sentence paragraphs, no
  headings, no bullet lists (see #47).
