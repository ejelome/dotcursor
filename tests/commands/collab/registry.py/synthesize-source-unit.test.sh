#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-synthesize-source-unit"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Synthesize Source Unit" >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"
"$ROOT/commands/collab/engine/registry.py" join-participants "$TARGET" pe --agent-id codex >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" turn-order pe --caller-role mod >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" active-phase Discussion --force --caller-role mod >/dev/null

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
raw_path="${projection_path%.md}-raw.md"

speak_as_pe() {
  local content_file="$1"
  local state revision
  state="$("$ROOT/commands/collab/engine/registry.py" speak-state "$TARGET" pe)"
  revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["registryRevision"])' <<<"$state")"
  "$ROOT/commands/collab/engine/registry.py" speak-render "$TARGET" pe \
    --content-file "$content_file" \
    --observed-revision "$revision" \
    --caller-role pe >/dev/null
}

synthesize_with_body() {
  local unique="$1"
  local state revision phase round anchors
  state="$("$ROOT/commands/collab/engine/registry.py" synthesize-state "$TARGET")"
  revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["observedRevision"])' <<<"$state")"
  phase="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["phase"])' <<<"$state")"
  round="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["roundNumber"])' <<<"$state")"
  anchors="$(python3 -c 'import json,sys; print(", ".join(json.load(sys.stdin)["contributionAnchors"]))' <<<"$state")"
  cat >synthesis.md <<EOF
## $phase — Round $round synthesis

| Role | Stance | Summary |
|------|--------|---------|
| pe | qualifies | $unique |

**Converged**
- preserve source anchors: $anchors

**Open**
- none

**Action-plan deltas**
- none

_Synthesized by sy/codex from registry revision $revision._
EOF
  "$ROOT/commands/collab/engine/registry.py" synthesize "$TARGET" \
    --observed-revision "$revision" \
    --content-file synthesis.md \
    --agent-id codex
}

cat >first.md <<'EOF'
STANCE: qualifies
First source contribution.
EOF
speak_as_pe first.md

state="$("$ROOT/commands/collab/engine/registry.py" synthesize-state "$TARGET")"
stale_revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["observedRevision"])' <<<"$state")"
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" description "revision guard fixture" --caller-role mod >/dev/null
cat >stale-synthesis.md <<'EOF'
## Discussion — Round 1 synthesis

stale write fixture
EOF
set +e
stale_output="$("$ROOT/commands/collab/engine/registry.py" synthesize "$TARGET" --observed-revision "$stale_revision" --content-file stale-synthesis.md --agent-id codex 2>&1)"
stale_status=$?
set -e
if [[ "$stale_status" -eq 0 || "$stale_output" != *'RESUME: commands/collab/engine/registry.py synthesize-state'* ]]; then
  printf 'FAIL: synthesize accepted stale observed revision\n%s\n' "$stale_output" >&2
  exit 1
fi

first_unique='UNIQUE-SYNTHESIS-BODY-FIRST'
synthesize_with_body "$first_unique" >first-synthesize.out
first_body_path="$(awk -F': ' '/^path:/ {print $2}' first-synthesize.out)"
grep -Fq "$first_unique" "$first_body_path"
grep -Fq "$first_unique" "$projection_path"
if grep -Fq "$first_unique" "$REGISTRY"; then
  printf 'FAIL: registry stored synthesis body text\n' >&2
  exit 1
fi
if grep -Fq "$first_unique" "$raw_path"; then
  printf 'FAIL: raw transcript stored synthesis body text\n' >&2
  exit 1
fi

"$ROOT/commands/collab/engine/registry.py" set "$TARGET" active-phase Conclusion --force --caller-role mod >/dev/null
python3 - "$ROOT" "$REGISTRY" "$TARGET" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
registry_path = Path(sys.argv[2])
target = sys.argv[3]
sys.path.insert(0, str(root))

from commands.collab.engine.registry import (  # noqa: E402
    load_registry,
    read_contribution_store_for_entry,
    read_synthesis_store_for_entry,
    resolve_collab,
)
from commands.collab.engine.synthesis import synthesis_blocks_for_projection  # noqa: E402

data = load_registry(registry_path)
entry = resolve_collab(data, target)
store = read_contribution_store_for_entry(registry_path, entry)
synthesis_store = read_synthesis_store_for_entry(registry_path, entry, include_content=True)
block = '\n'.join(synthesis_blocks_for_projection(data, entry, store, synthesis_store)['Discussion'])
assert 'Stale' in block, block
assert 'produced at revision' in block, block
PY

"$ROOT/commands/collab/engine/registry.py" set "$TARGET" active-phase Discussion --force --caller-role mod >/dev/null
cat >second.md <<'EOF'
STANCE: qualifies
Second source contribution.
EOF
speak_as_pe second.md
second_unique='UNIQUE-SYNTHESIS-BODY-SECOND'
synthesize_with_body "$second_unique" >second-synthesize.out

cat >rewrite.md <<'EOF'
STANCE: qualifies
Rewritten second source contribution.
EOF
"$ROOT/commands/collab/engine/registry.py" rewrite-speak-render "$TARGET" pe \
  --content-file rewrite.md \
  --caller-role pe >/dev/null

python3 - "$ROOT" "$REGISTRY" "$TARGET" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
registry_path = Path(sys.argv[2])
target = sys.argv[3]
sys.path.insert(0, str(root))

from commands.collab.engine.registry import (  # noqa: E402
    load_registry,
    read_contribution_store_for_entry,
    read_synthesis_store_for_entry,
    resolve_collab,
)
from commands.collab.engine.synthesis import synthesis_blocks_for_projection  # noqa: E402

data = load_registry(registry_path)
entry = resolve_collab(data, target)
store = read_contribution_store_for_entry(registry_path, entry)
synthesis_store = read_synthesis_store_for_entry(registry_path, entry, include_content=True)
block = '\n'.join(synthesis_blocks_for_projection(data, entry, store, synthesis_store)['Discussion'])
assert 'Stale' in block, block
assert 'produced at revision' in block, block
PY

rewrite_unique='UNIQUE-SYNTHESIS-BODY-REWRITE'
synthesize_with_body "$rewrite_unique" >rewrite-synthesize.out
"$ROOT/commands/collab/engine/registry.py" retract-speak "$TARGET" pe \
  --reason "source-unit test" \
  --caller-role pe >/dev/null

python3 - "$ROOT" "$REGISTRY" "$TARGET" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
registry_path = Path(sys.argv[2])
target = sys.argv[3]
sys.path.insert(0, str(root))

from commands.collab.engine.registry import (  # noqa: E402
    load_registry,
    read_contribution_store_for_entry,
    read_synthesis_store_for_entry,
    resolve_collab,
)
from commands.collab.engine.synthesis import synthesis_blocks_for_projection  # noqa: E402

data = load_registry(registry_path)
entry = resolve_collab(data, target)
store = read_contribution_store_for_entry(registry_path, entry)
synthesis_store = read_synthesis_store_for_entry(registry_path, entry, include_content=True)
block = '\n'.join(synthesis_blocks_for_projection(data, entry, store, synthesis_store)['Discussion'])
assert 'Stale' in block, block
assert 'produced at revision' in block, block
visible = [item for item in store['contributions'] if not item.get('retracted')]
assert [item['anchor'] for item in visible] == ['discussion-pe-1'], visible
PY

printf 'OK: synthesize source unit guards stale write, rewrite, and retract cases\n'
