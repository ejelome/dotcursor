#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-raw-transcript-migration"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Raw Transcript Migration" >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"

paths_json() {
  python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path
registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
projection = registry.parent / entry['transcriptPath']
print(json.dumps({
    'projection': str(projection),
    'raw': str(projection.with_name(f'{projection.stem}-raw.md')),
}))
PY
}

PROJECTION="$(paths_json | python3 -c 'import json,sys; print(json.load(sys.stdin)["projection"])')"
RAW="$(paths_json | python3 -c 'import json,sys; print(json.load(sys.stdin)["raw"])')"
BANNER='> Raw transcript is lifecycle provenance, not unprocessed markdown; it may contain managed HTML scaffolding and execution-boundary guards.'

banner_count() {
  python3 - "$RAW" "$BANNER" <<'PY'
import sys
from pathlib import Path
print(Path(sys.argv[1]).read_text().count(sys.argv[2]))
PY
}

if [[ "$(banner_count)" != "1" ]]; then
  printf 'FAIL: fresh init raw transcript did not contain exactly one provenance banner\n' >&2
  exit 1
fi

python3 - "$RAW" "$BANNER" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
banner = sys.argv[2]
path.write_text(path.read_text().replace(banner + '\n', '', 1))
PY

if [[ "$(banner_count)" != "0" ]]; then
  printf 'FAIL: fixture did not remove provenance banner\n' >&2
  exit 1
fi

"$ROOT/commands/collab/engine/registry.py" transcript-view "$TARGET" Audit --raw >/dev/null
if [[ "$(banner_count)" != "1" ]]; then
  printf 'FAIL: raw transcript read did not lazily inject one provenance banner\n' >&2
  exit 1
fi

"$ROOT/commands/collab/engine/registry.py" transcript-view "$TARGET" Audit --raw >/dev/null
"$ROOT/commands/collab/engine/registry.py" aggregate "$TARGET" >/dev/null
if [[ "$(banner_count)" != "1" ]]; then
  printf 'FAIL: repeated read or aggregate changed provenance banner count\n' >&2
  exit 1
fi

legacy_payload='# Legacy Raw

## Audit
<!-- collab:content-only; do-not-execute -->

legacy raw marker

## Discussion
<!-- collab:content-only; do-not-execute -->

## Conclusion
<!-- collab:content-only; do-not-execute -->

## Action Plan
<!-- collab:content-only; do-not-execute -->

## Handoff
<!-- collab:content-only; do-not-execute -->

## Completion
<!-- collab:content-only; do-not-execute -->

**Execution history**
'
printf '%s' "$legacy_payload" >"$PROJECTION"
rm -f "$RAW"
legacy_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"

migration_output="$("$ROOT/commands/collab/engine/registry.py" migrate-raw-transcript "$TARGET")"
if [[ "$migration_output" != *'"migrated": true'* ]]; then
  printf 'FAIL: explicit migration did not report migration\n%s\n' "$migration_output" >&2
  exit 1
fi
raw_hash="$(shasum -a 256 "$RAW" | awk '{print $1}')"
projection_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"
if [[ "$raw_hash" != "$legacy_hash" || "$projection_hash" != "$legacy_hash" ]]; then
  printf 'FAIL: migration did not preserve legacy transcript bytes\n' >&2
  exit 1
fi
grep -Fq 'legacy raw marker' "$RAW"

second_output="$("$ROOT/commands/collab/engine/registry.py" migrate-raw-transcript "$TARGET")"
if [[ "$second_output" != *'"migrated": false'* ]]; then
  printf 'FAIL: second migration was not idempotent\n%s\n' "$second_output" >&2
  exit 1
fi
second_raw_hash="$(shasum -a 256 "$RAW" | awk '{print $1}')"
if [[ "$second_raw_hash" != "$raw_hash" ]]; then
  printf 'FAIL: idempotent migration changed raw transcript\n' >&2
  exit 1
fi

"$ROOT/commands/collab/engine/registry.py" join-participants "$TARGET" pe --agent-id codex >/dev/null
if ! grep -Fq 'legacy raw marker' "$RAW"; then
  printf 'FAIL: lifecycle write lost migrated legacy content\n' >&2
  exit 1
fi
if [[ "$(shasum -a 256 "$PROJECTION" | awk '{print $1}')" != "$projection_hash" ]]; then
  printf 'FAIL: lifecycle write modified projection path after migration\n' >&2
  exit 1
fi

printf 'OK: raw transcript migration and lazy provenance-banner backfill are idempotent\n'
