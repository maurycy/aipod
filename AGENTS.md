# AGENTS.md

aipod is a single POSIX sh script managing a podman dev container.

- `#!/bin/sh`, no bashisms; macOS /bin/sh is bash-as-sh and pre-sets variables
  like `HOSTNAME` - give config variables explicit defaults.
- `shellcheck aipod install.sh` must pass (CI).
- No test suite: copy `aipod` + `aipod.conf` to a scratch dir (script dir beats
  XDG), use an absolute `CONTAINERFILE`, set `HOSTNAME` to something other
  than `aipod`, assert with `podman inspect`.
- Commits: `feat:`/`fix:`/`chore:`, variable names in backticks.
- PR descriptions are extremely minimal: a few one-sentence paragraphs, no
  headings, no bullet lists (see #47).
