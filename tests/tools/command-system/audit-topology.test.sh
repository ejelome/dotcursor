#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

make_catalog() {
  local root="$1"
  mkdir -p "$root/commands"
  cat >"$root/commands/commands.md" <<'CATALOG'
# /commands

<!-- BEGIN GENERATED:COMMANDS_ROSTER -->
| Slash | Signature | Public router | Private functions |
| --- | --- | --- | --- |
| `/demo` | `/demo <run>` | [demo](demo/index.md) | [run](demo/run/index.md) |

| Route | Private function |
| --- | --- |
| `/demo run` | [demo/run/index.md](demo/run/index.md) |
<!-- END GENERATED:COMMANDS_ROSTER -->
CATALOG
}

clean="$TMPDIR/clean"
make_catalog "$clean"
mkdir -p "$clean/commands/demo/run"
printf '# /demo\n' >"$clean/commands/demo/index.md"
printf '# /demo run\n' >"$clean/commands/demo/run/index.md"
COMMAND_CONFIG_ROOT="$clean" "$ROOT/tools/command-system/audit-topology.sh" >/dev/null

missing="$TMPDIR/missing"
make_catalog "$missing"
mkdir -p "$missing/commands/demo"
printf '# /demo\n' >"$missing/commands/demo/index.md"
set +e
COMMAND_CONFIG_ROOT="$missing" "$ROOT/tools/command-system/audit-topology.sh" >"$TMPDIR/missing.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected missing command entry point to fail\n' >&2
  exit 1
fi
if ! grep -Fxq 'ERROR: missing command entry point: commands/demo/run/index.md' "$TMPDIR/missing.out"; then
  printf 'FAIL: missing output did not name required command path\n' >&2
  cat "$TMPDIR/missing.out" >&2
  exit 1
fi

orphan="$TMPDIR/orphan"
make_catalog "$orphan"
mkdir -p "$orphan/commands/demo/run" "$orphan/commands/demo/extra"
printf '# /demo\n' >"$orphan/commands/demo/index.md"
printf '# /demo run\n' >"$orphan/commands/demo/run/index.md"
printf '# /demo extra\n' >"$orphan/commands/demo/extra/index.md"
COMMAND_CONFIG_ROOT="$orphan" "$ROOT/tools/command-system/audit-topology.sh" >"$TMPDIR/orphan.out" 2>&1
if ! grep -Fxq 'WARN: orphaned entry point: commands/demo/extra/index.md (no catalog entry for command demo/extra)' "$TMPDIR/orphan.out"; then
  printf 'FAIL: orphan output did not warn with stable path\n' >&2
  cat "$TMPDIR/orphan.out" >&2
  exit 1
fi

broken_link="$TMPDIR/broken-link"
make_catalog "$broken_link"
mkdir -p "$broken_link/commands/demo"
printf '# /demo\n' >"$broken_link/commands/demo/index.md"
set +e
COMMAND_CONFIG_ROOT="$broken_link" "$ROOT/tools/command-system/audit-topology.sh" >"$TMPDIR/broken-link.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected generated catalog link resolution to fail\n' >&2
  exit 1
fi
if ! grep -Fxq 'ERROR: generated catalog link target missing: commands/demo/run/index.md' "$TMPDIR/broken-link.out"; then
  printf 'FAIL: generated link output did not name missing target\n' >&2
  cat "$TMPDIR/broken-link.out" >&2
  exit 1
fi

migration="$TMPDIR/migration"
make_catalog "$migration"
python3 - "$migration/commands/commands.md" <<'PY'
from pathlib import Path
path = Path(__import__("sys").argv[1])
text = path.read_text().replace("[demo](demo/index.md)", "[demo](demo.md)")
path.write_text(text)
PY
mkdir -p "$migration/commands/demo/run"
printf '# /demo flat\n' >"$migration/commands/demo.md"
printf '# /demo run\n' >"$migration/commands/demo/run/index.md"
COMMAND_CONFIG_ROOT="$migration" "$ROOT/tools/command-system/audit-topology.sh" --migration >/dev/null

printf 'OK: topology audit enforces registered index.md entries and orphan warnings\n'
