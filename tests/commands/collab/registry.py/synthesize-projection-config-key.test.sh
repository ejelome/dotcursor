#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

python3 - "$ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root))

from commands.collab.engine.registry import (  # noqa: E402
    contribution_store_path_for_entry,
    projection_transcript_path_for_entry,
)
from commands.collab.engine.transcript_render import (  # noqa: E402
    projection_mode_for_entry,
    raw_transcript_path_for_entry,
)

registry_path = Path('/tmp/collab-projection-config/registry.json')
base = {
    'title': 'Projection Config',
    'transcriptPath': 'records/default.md',
}

projection_entry = {
    **base,
    'projection': {
        'moderatorProjectTranscriptPath': 'records/projection.md',
        'contributionStorePath': 'records/projection-store.json',
        'rawTranscriptPath': 'records/projection-raw.md',
    },
}
assert projection_transcript_path_for_entry(projection_entry) == 'records/projection.md'
assert raw_transcript_path_for_entry(projection_entry) == 'records/projection-raw.md'
assert projection_mode_for_entry(projection_entry) == 'collapsed'
assert contribution_store_path_for_entry(
    registry_path, projection_entry
) == registry_path.parent / 'records/projection-store.json'

legacy_entry = {
    **base,
    'aggregate': {
        'moderatorProjectTranscriptPath': 'records/legacy-projection.md',
        'contributionStorePath': 'records/legacy-store.json',
        'rawTranscriptPath': 'records/legacy-raw.md',
    },
}
assert projection_transcript_path_for_entry(legacy_entry) == 'records/legacy-projection.md'
assert raw_transcript_path_for_entry(legacy_entry) == 'records/legacy-raw.md'
assert projection_mode_for_entry(legacy_entry) == 'collapsed'
assert contribution_store_path_for_entry(
    registry_path, legacy_entry
) == registry_path.parent / 'records/legacy-store.json'

legacy_mode_entry = {
    **base,
    'aggregate': {
        'mode': 'per-piece',
    },
}
assert projection_mode_for_entry(legacy_mode_entry) == 'per-piece'

mixed_entry = {
    **base,
    'projection': {
        'moderatorProjectTranscriptPath': 'records/new-projection.md',
    },
    'aggregate': {
        'moderatorProjectTranscriptPath': 'records/old-projection.md',
        'contributionStorePath': 'records/old-store.json',
        'rawTranscriptPath': 'records/old-raw.md',
    },
}
assert projection_transcript_path_for_entry(mixed_entry) == 'records/new-projection.md'
assert raw_transcript_path_for_entry(mixed_entry) == 'records/old-raw.md'
assert contribution_store_path_for_entry(
    registry_path, mixed_entry
) == registry_path.parent / 'records/old-store.json'

derived_entry = {
    **base,
    'projection': {
        'moderatorProjectTranscriptPath': 'records/custom-projection.md',
        'mode': 'per-piece',
    },
}
assert projection_mode_for_entry(derived_entry) == 'per-piece'
assert contribution_store_path_for_entry(
    registry_path, derived_entry
) == registry_path.parent / 'records/custom-projection-contributions.json'

print('OK: projection config key overrides legacy aggregate with field fallback')
PY

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-projection-mode-setter"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Projection Mode Setter" >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"

python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
assert entry['projection']['mode'] == 'collapsed'
PY

"$ROOT/commands/collab/engine/registry.py" set "$TARGET" projection.mode per-piece --caller-role mod >/dev/null

python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
assert entry['projection']['mode'] == 'per-piece'
PY

set +e
invalid_output="$("$ROOT/commands/collab/engine/registry.py" set "$TARGET" projection.mode verbose --caller-role mod 2>&1)"
invalid_status=$?
set -e

if [[ "$invalid_status" -eq 0 || "$invalid_output" != *'projection.mode must be one of'* ]]; then
  printf 'FAIL: invalid projection.mode was accepted\n%s\n' "$invalid_output" >&2
  exit 1
fi
