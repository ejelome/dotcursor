#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

one="$TMPDIR/one"
mkdir -p "$one/commands/demo/run" "$one/commands/demo/show"
printf '[shared](../shared.md)\n' >"$one/commands/demo/run/index.md"
printf '# /demo show\n' >"$one/commands/demo/show/index.md"
COMMAND_CONFIG_ROOT="$one" "$ROOT/tools/command-system/audit-placement.sh" >/dev/null

same_ns="$TMPDIR/same-ns"
mkdir -p "$same_ns/commands/demo/run" "$same_ns/commands/demo/show"
printf '[shared](../shared.md)\n' >"$same_ns/commands/demo/run/index.md"
printf '/demo show ../shared.md\n' >"$same_ns/commands/demo/show/index.md"
set +e
COMMAND_CONFIG_ROOT="$same_ns" "$ROOT/tools/command-system/audit-placement.sh" >"$TMPDIR/same-ns.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected same-namespace shared command file to fail placement\n' >&2
  exit 1
fi
if ! grep -Fq 'ERROR: shared file must move to core/demo/: commands/demo/shared.md' "$TMPDIR/same-ns.out"; then
  printf 'FAIL: same-namespace placement error was not stable\n' >&2
  cat "$TMPDIR/same-ns.out" >&2
  exit 1
fi

cross="$TMPDIR/cross"
mkdir -p "$cross/commands/demo/run" "$cross/commands/other/show"
printf '[shared](../../shared.md)\n' >"$cross/commands/demo/run/index.md"
printf '[shared](../../shared.md)\n' >"$cross/commands/other/show/index.md"
set +e
COMMAND_CONFIG_ROOT="$cross" "$ROOT/tools/command-system/audit-placement.sh" >"$TMPDIR/cross.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected cross-namespace shared command file to fail placement\n' >&2
  exit 1
fi
if ! grep -Fq 'ERROR: cross-namespace shared file must move to core/: commands/shared.md' "$TMPDIR/cross.out"; then
  printf 'FAIL: cross-namespace placement error was not stable\n' >&2
  cat "$TMPDIR/cross.out" >&2
  exit 1
fi

clean="$TMPDIR/clean"
mkdir -p "$clean/commands/demo/run" "$clean/commands/demo/show" "$clean/commands/demo/list" "$clean/commands/other/read" "$clean/core/demo" "$clean/core"
printf '[shared](../../../core/demo/shared.md)\n' >"$clean/commands/demo/run/index.md"
printf '[shared](../../../core/demo/shared.md)\n' >"$clean/commands/demo/show/index.md"
printf '[cross](../../../core/shared.md)\n' >"$clean/commands/demo/list/index.md"
printf '[cross](../../../core/shared.md)\n' >"$clean/commands/other/read/index.md"
COMMAND_CONFIG_ROOT="$clean" "$ROOT/tools/command-system/audit-placement.sh" >/dev/null

long_dispatch="$TMPDIR/long-dispatch"
mkdir -p "$long_dispatch/commands/demo/run" "$long_dispatch/commands/demo/show"
printf '/demo show nested ../shared.md\n' >"$long_dispatch/commands/demo/run/index.md"
printf '[shared](../shared.md)\n' >"$long_dispatch/commands/demo/show/index.md"
set +e
COMMAND_CONFIG_ROOT="$long_dispatch" "$ROOT/tools/command-system/audit-placement.sh" >"$TMPDIR/long-dispatch.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected long slash-dispatch reference to fail placement\n' >&2
  exit 1
fi
if ! grep -Fq 'ERROR: shared file must move to core/demo/: commands/demo/shared.md' "$TMPDIR/long-dispatch.out"; then
  printf 'FAIL: long slash-dispatch placement error was not stable\n' >&2
  cat "$TMPDIR/long-dispatch.out" >&2
  exit 1
fi

cross_ns_core="$TMPDIR/cross-ns-core"
mkdir -p "$cross_ns_core/commands/demo/run" "$cross_ns_core/commands/other/show" "$cross_ns_core/core/demo"
printf '[shared](../../../core/demo/shared.md)\n' >"$cross_ns_core/commands/demo/run/index.md"
printf '[shared](../../../core/demo/shared.md)\n' >"$cross_ns_core/commands/other/show/index.md"
set +e
COMMAND_CONFIG_ROOT="$cross_ns_core" "$ROOT/tools/command-system/audit-placement.sh" >"$TMPDIR/cross-ns-core.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected cross-namespace core/<ns>/ target to fail placement\n' >&2
  exit 1
fi
if ! grep -Fq 'ERROR: cross-namespace shared file must move to core/: core/demo/shared.md' "$TMPDIR/cross-ns-core.out"; then
  printf 'FAIL: cross-namespace core/<ns>/ placement error was not stable\n' >&2
  cat "$TMPDIR/cross-ns-core.out" >&2
  exit 1
fi

migration="$TMPDIR/migration"
mkdir -p "$migration/commands/demo/run" "$migration/commands/other/read"
printf '[shared](demo/shared.md)\n' >"$migration/commands/demo.md"
printf '[shared](../shared.md)\n' >"$migration/commands/demo/run/index.md"
printf '[shared](other/shared.md)\n' >"$migration/commands/other.md"
printf '[shared](../shared.md)\n' >"$migration/commands/other/read/index.md"
set +e
COMMAND_CONFIG_ROOT="$migration" "$ROOT/tools/command-system/audit-placement.sh" --migration >"$TMPDIR/migration.out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'FAIL: expected migration mode to read flat and directory sources\n' >&2
  exit 1
fi
if ! grep -Fq 'ERROR: shared file must move to core/demo/: commands/demo/shared.md' "$TMPDIR/migration.out"; then
  printf 'FAIL: migration output did not include flat and directory same-namespace sources\n' >&2
  cat "$TMPDIR/migration.out" >&2
  exit 1
fi

printf 'OK: placement audit counts command references and enforces core locations\n'
