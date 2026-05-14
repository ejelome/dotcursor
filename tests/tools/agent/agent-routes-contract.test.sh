#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

grep -Fq 'global runtime root' _functions/agent/_run-root.md || fail "_run-root.md does not define global runtime root"
grep -Fq 'target repository root' _functions/agent/_run-root.md || fail "_run-root.md does not define target repository root"

grep -Fq 'not `~/.cursor`' _functions/agent/install.md || fail "install.md lacks runtime-root abort"
grep -Fq 'not `~/.cursor`' _functions/agent/upgrade.md || fail "upgrade.md lacks runtime-root abort"

grep -Fq 'TODO(install)' _templates/AGENTS.md || fail "AGENTS template lacks TODO(install)"
grep -Fq 'TODO(patch)' _templates/REPOSITORY.md || fail "REPOSITORY template lacks TODO(patch)"

if grep -R 'TODO(agent)' _functions/agent _templates _tests/_templates.md commands/commands.md >/dev/null; then
  grep -R 'TODO(agent)' _functions/agent _templates _tests/_templates.md commands/commands.md >&2
  fail "agent route contract still references TODO(agent)"
fi

grep -Fq 'no installed scaffold file contains unresolved `<!-- TODO(install): ... -->` markers' _functions/agent/install.md || fail "install.md lacks TODO(install) validation"
grep -Fq 'no `<!-- TODO(patch): ... -->` markers remain' _functions/agent/patch.md || fail "patch.md lacks TODO(patch) validation"
grep -Fq 'if any `TODO(install)` marker would survive in the candidate patch, **ABORT**' _functions/agent/upgrade.md || fail "upgrade.md lacks unresolved TODO(install) overwrite abort"

grep -Fq 'include a command path only when that exact path exists in the target repo' _functions/agent/patch.md || fail "patch.md lacks deterministic validation-command inference"
grep -Fq '_functions/test/run.md' _functions/agent/patch.md || fail "patch.md lacks sibling-route failed example"

printf 'OK: agent route contract covers run-root and marker-class invariants\n'
