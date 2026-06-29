#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-restore-target"
OTHER="$RUN_DATE-other-collab"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Restore Target" >/dev/null
"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Other Collab" >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" description "target-before" --caller-role mod >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" description "target-after" --caller-role mod >/dev/null
RESTORE_INDEX="$("$ROOT/commands/collab/engine/registry.py" log "$TARGET" | awk 'NR==1 { gsub(/^#/, "", $1); print $1 }')"
"$ROOT/commands/collab/engine/registry.py" set "$OTHER" description "other-after" --caller-role mod >/dev/null

REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"
BEFORE_EVENT_COUNT="$(find "$(dirname "$REGISTRY")/revisions/$TARGET" -name '[0-9]*.json' | wc -l | tr -d ' ')"

"$ROOT/commands/collab/engine/registry.py" restore "$TARGET" --to "$RESTORE_INDEX" --caller-role mod >/dev/null

python3 - "$REGISTRY" "$TARGET" "$OTHER" "$RESTORE_INDEX" "$BEFORE_EVENT_COUNT" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
target_id = sys.argv[2]
other_id = sys.argv[3]
restore_index = int(sys.argv[4])
before_event_count = int(sys.argv[5])
data = json.loads(registry.read_text())
by_id = {entry['id']: entry for entry in data['collabs']}
assert data['activeCollabId'] == other_id, data['activeCollabId']
assert by_id[target_id]['description'] == 'target-before', by_id[target_id]
assert by_id[other_id]['description'] == 'other-after', by_id[other_id]
event_dir = registry.parent / 'revisions' / target_id
events = sorted(path for path in event_dir.glob('*.json') if path.stem.isdigit())
assert len(events) == before_event_count + 1, [path.name for path in events]
latest = json.loads(events[-1].read_text())
assert latest['eventType'] == 'restore-content', latest
assert latest['summary'].endswith(f'from eventIndex {restore_index}'), latest
assert isinstance(latest.get('_legacyBefore'), dict), latest
PY

printf 'OK: restore --to projects target collab, preserves other collabs, and appends an event\n'
