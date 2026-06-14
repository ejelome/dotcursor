#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-aggregate-projection-output"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Aggregate Projection Output" >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"
"$ROOT/commands/collab/engine/registry.py" join-participants "$TARGET" pe --agent-id codex >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" turn-order pe --caller-role mod >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" active-phase Discussion --force --caller-role mod >/dev/null

state="$("$ROOT/commands/collab/engine/registry.py" speak-state "$TARGET" pe)"
revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["registryRevision"])' <<<"$state")"

printf "STANCE: qualifies\nModerator&#x27;s excerpt with pipe | marker.\n" >excerpt.md
python3 - <<'PY' >full-body.md
print(' '.join(f'fullbodytoken{i}' for i in range(80)))
PY

"$ROOT/commands/collab/engine/registry.py" speak-render "$TARGET" pe \
  --content-file excerpt.md \
  --full-body-file full-body.md \
  --observed-revision "$revision" \
  --caller-role pe >/dev/null

"$ROOT/commands/collab/engine/registry.py" set "$TARGET" active-phase Discussion --force --caller-role mod >/dev/null
state="$("$ROOT/commands/collab/engine/registry.py" speak-state "$TARGET" pe)"
revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["registryRevision"])' <<<"$state")"
printf 'Second contribution keeps anchor identity distinct.\n' >second.md
"$ROOT/commands/collab/engine/registry.py" speak-render "$TARGET" pe \
  --content-file second.md \
  --observed-revision "$revision" \
  --caller-role pe >/dev/null

projection_path="$(python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path
registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
print(registry.parent / entry['transcriptPath'])
PY
)"

printf 'sentinel projection bytes\n' >"$projection_path"
"$ROOT/commands/collab/engine/registry.py" aggregate "$TARGET" >/dev/null

grep -Fq "Moderator's excerpt with pipe \\| marker." "$projection_path"
grep -Fq 'fullbodytoken79' "$projection_path"
grep -Fq 'discussion-pe-1' "$projection_path"
grep -Fq 'discussion-pe-2' "$projection_path"

if grep -Fq '&#x27;' "$projection_path"; then
  printf 'FAIL: aggregate projection exposed an apostrophe HTML entity\n' >&2
  exit 1
fi

python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path
registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
store = registry.parent / Path(entry['transcriptPath']).with_name(f"{Path(entry['transcriptPath']).stem}-contributions.json")
data = json.loads(store.read_text())
data['contributions'][0]['content'] = ' '.join(f'overflow{i}' for i in range(2048))
store.write_text(json.dumps(data, indent=2) + '\n')
PY

printf 'sentinel projection bytes\n' >"$projection_path"
set +e
fail_output="$(bash -c 'ulimit -f 1; "$1" aggregate "$2"' _ "$ROOT/commands/collab/engine/registry.py" "$TARGET" 2>&1)"
fail_status=$?
set -e

if [[ "$fail_status" -eq 0 ]]; then
  printf 'FAIL: aggregate succeeded under a file-size limit that should fail the temp write\n' >&2
  exit 1
fi
if [[ "$(cat "$projection_path")" != "sentinel projection bytes" ]]; then
  printf 'FAIL: aggregate failure modified the existing projection\n%s\n' "$fail_output" >&2
  exit 1
fi
if find "$(dirname "$projection_path")" -name ".$(basename "$projection_path").*.tmp" | grep -q .; then
  printf 'FAIL: aggregate failure left a temp projection file behind\n' >&2
  exit 1
fi

printf 'OK: aggregate renders full projection content, plain entities, stable anchors, and atomic output\n'
