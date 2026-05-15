#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export CURSOR_COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"

"$ROOT/tools/collab/registry.py" init --agent-id codex "Home State Init" >/dev/null
REGISTRY="$("$ROOT/tools/collab/registry.py" registry-path)"

python3 - "$REGISTRY" "$CURSOR_COLLAB_STATE_HOME" "$RUN_DATE-home-state-init" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
state_home = Path(sys.argv[2]).resolve()
target = sys.argv[3]
identity = json.loads(Path('.collab-project.json').read_text())
assert identity['schemaVersion'] == 1
assert identity['projectId']
assert registry == state_home / identity['projectId'] / 'registry.json'
assert registry.exists()
assert not Path('.collabs/registry.json').exists()
entry = json.loads(registry.read_text())['collabs'][0]
assert entry['id'] == target
assert entry['transcriptPath'] == f'records/{target}.md'
assert (registry.parent / entry['transcriptPath']).exists()
PY

MIGRATE_DIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR" "$MIGRATE_DIR"' EXIT
cd "$MIGRATE_DIR"
export CURSOR_COLLAB_STATE_HOME="$MIGRATE_DIR/migrated-state-home"

mkdir -p .collabs
"$ROOT/tools/collab/registry.py" --registry .collabs/registry.json init --agent-id codex "Legacy Migrate" >/dev/null
mkdir -p .collabs/records
mv "records/${RUN_DATE}-legacy-migrate.md" ".collabs/records/${RUN_DATE}-legacy-migrate.md"
rmdir records
python3 - "$RUN_DATE-legacy-migrate" <<'PY'
import json
import sys
from pathlib import Path

target = sys.argv[1]
path = Path('.collabs/registry.json')
data = json.loads(path.read_text())
data['collabs'][0]['transcriptPath'] = f'.collabs/records/{target}.md'
path.write_text(json.dumps(data, indent=2) + '\n')
PY

"$ROOT/tools/collab/registry.py" list >/dev/null
MIGRATED_REGISTRY="$("$ROOT/tools/collab/registry.py" registry-path)"

python3 - "$MIGRATED_REGISTRY" "$RUN_DATE-legacy-migrate" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
target = sys.argv[2]
identity = json.loads(Path('.collab-project.json').read_text())
assert registry == (Path.cwd() / 'migrated-state-home' / identity['projectId'] / 'registry.json').resolve()
entry = json.loads(registry.read_text())['collabs'][0]
assert entry['transcriptPath'] == f'records/{target}.md'
assert (registry.parent / entry['transcriptPath']).exists()
stub = json.loads(Path('.collabs/project.json').read_text())
assert stub == {'schemaVersion': 1, 'projectId': identity['projectId']}
assert not Path('.collabs/registry.json').exists()
assert not Path(f'.collabs/records/{target}.md').exists()
PY

printf 'OK: collab registry resolves through project id and migrates legacy repo-local state\n'
