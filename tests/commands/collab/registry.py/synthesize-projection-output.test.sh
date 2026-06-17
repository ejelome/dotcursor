#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-synthesize-projection-output"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Synthesize Projection Output" >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"
"$ROOT/commands/collab/engine/registry.py" join-participants "$TARGET" pe --agent-id codex >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" turn-order pe --caller-role mod >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" projection.mode per-piece --caller-role mod >/dev/null
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

synthesize_projection() {
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
| pe | qualifies | Projection output preserves full contribution detail. |

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
    --agent-id codex >/dev/null
}

printf 'sentinel projection bytes\n' >"$projection_path"
synthesize_projection

grep -Fq '## Discussion — Round 1 synthesis' "$projection_path"
grep -Fq 'projectionMode: `per-piece`' "$projection_path"
grep -Fq 'Collab #' "$projection_path"
grep -Fq '**State**' "$projection_path"
grep -Fq '**Participants**' "$projection_path"
grep -Fq '**Table of contents**' "$projection_path"
grep -Fq '**Projection metadata**' "$projection_path"
grep -Fq '| Source | Role | Stance | Detail |' "$projection_path"
grep -Fq "Moderator's excerpt with pipe \\| marker." "$projection_path"
grep -Fq 'fullbodytoken79' "$projection_path"
grep -Fq 'discussion-pe-1' "$projection_path"
grep -Fq 'discussion-pe-2' "$projection_path"

python3 - "$projection_path" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
assert text.index('**State**') < text.index('**Participants**')
assert text.index('**Participants**') < text.index('**Table of contents**')
assert text.index('**Table of contents**') < text.index('## Discussion')
assert text.index('## Discussion') < text.index('**Projection metadata**')
assert text.index('projectionMode: `per-piece`') > text.index('**Projection metadata**')
PY

if grep -Fq '&#x27;' "$projection_path"; then
  printf 'FAIL: synthesize projection exposed an apostrophe HTML entity\n' >&2
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
state="$("$ROOT/commands/collab/engine/registry.py" synthesize-state "$TARGET")"
revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["observedRevision"])' <<<"$state")"
phase="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["phase"])' <<<"$state")"
round="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["roundNumber"])' <<<"$state")"
cat >failure-synthesis.md <<EOF
## $phase — Round $round synthesis

| Role | Stance | Summary |
|------|--------|---------|
| pe | qualifies | Large projection write should fail atomically. |

**Converged**
- preserve oversized source detail

**Open**
- none

**Action-plan deltas**
- none

_Synthesized by sy/codex from registry revision $revision._
EOF
set +e
fail_output="$(bash -c 'ulimit -f 1; "$1" synthesize "$2" --observed-revision "$3" --content-file "$4" --agent-id codex' _ "$ROOT/commands/collab/engine/registry.py" "$TARGET" "$revision" "$PWD/failure-synthesis.md" 2>&1)"
fail_status=$?
set -e

if [[ "$fail_status" -eq 0 ]]; then
  printf 'FAIL: synthesize succeeded under a file-size limit that should fail the temp write\n' >&2
  exit 1
fi
if [[ "$(cat "$projection_path")" != "sentinel projection bytes" ]]; then
  printf 'FAIL: synthesize failure modified the existing projection\n%s\n' "$fail_output" >&2
  exit 1
fi
if find "$(dirname "$projection_path")" -name ".$(basename "$projection_path").*.tmp" | grep -q .; then
  printf 'FAIL: synthesize failure left a temp projection file behind\n' >&2
  exit 1
fi

export COLLAB_STATE_HOME="$TMPDIR/collapsed-state-home"
COLLAPSED_TARGET="$RUN_DATE-synthesize-collapsed-output"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Synthesize Collapsed Output" >/dev/null
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"
"$ROOT/commands/collab/engine/registry.py" join-participants "$COLLAPSED_TARGET" pe --agent-id codex >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$COLLAPSED_TARGET" turn-order "mod pe" --caller-role mod >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$COLLAPSED_TARGET" active-phase Discussion --force --caller-role mod >/dev/null

collapsed_projection_path="$(python3 - "$REGISTRY" "$COLLAPSED_TARGET" <<'PY'
import json
import sys
from pathlib import Path
registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
print(registry.parent / entry['transcriptPath'])
PY
)"

speak_collapsed() {
  local role="$1"
  local content_file="$2"
  local state revision
  state="$("$ROOT/commands/collab/engine/registry.py" speak-state "$COLLAPSED_TARGET" "$role")"
  revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["registryRevision"])' <<<"$state")"
  "$ROOT/commands/collab/engine/registry.py" speak-render "$COLLAPSED_TARGET" "$role" \
    --content-file "$content_file" \
    --observed-revision "$revision" \
    --caller-role "$role" \
    --verbatim >/dev/null
}

synthesize_collapsed() {
  local unique="$1"
  local state revision phase round anchors
  state="$("$ROOT/commands/collab/engine/registry.py" synthesize-state "$COLLAPSED_TARGET")"
  revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["observedRevision"])' <<<"$state")"
  phase="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["phase"])' <<<"$state")"
  round="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["roundNumber"])' <<<"$state")"
  anchors="$(python3 -c 'import json,sys; print(", ".join(json.load(sys.stdin)["contributionAnchors"]))' <<<"$state")"
  cat >collapsed-synthesis.md <<EOF
## $phase — Round $round synthesis

$unique from anchors $anchors.

_Synthesized by sy/codex from registry revision $revision._
EOF
  "$ROOT/commands/collab/engine/registry.py" synthesize "$COLLAPSED_TARGET" \
    --observed-revision "$revision" \
    --content-file collapsed-synthesis.md \
    --agent-id codex >/dev/null
}

cat >collapsed-mod-1.md <<'EOF'
First moderator prompt.
EOF
cat >collapsed-pe-1.md <<'EOF'
STANCE: qualifies
First agent answer.
EOF
speak_collapsed mod collapsed-mod-1.md
speak_collapsed pe collapsed-pe-1.md
synthesize_collapsed 'ROUND-ONE-COLLAPSED'

cat >collapsed-mod-2.md <<'EOF'
Second moderator prompt.
EOF
cat >collapsed-pe-2.md <<'EOF'
STANCE: qualifies
Second agent answer.
EOF
speak_collapsed mod collapsed-mod-2.md
speak_collapsed pe collapsed-pe-2.md
synthesize_collapsed 'ROUND-TWO-COLLAPSED'

grep -Fq 'projectionMode: `collapsed`' "$collapsed_projection_path"
grep -Fq '**State**' "$collapsed_projection_path"
grep -Fq '**Participants**' "$collapsed_projection_path"
grep -Fq '**Table of contents**' "$collapsed_projection_path"
grep -Fq '**Projection metadata**' "$collapsed_projection_path"
if grep -Fq '| Source | Role | Stance | Detail |' "$collapsed_projection_path"; then
  printf 'FAIL: collapsed projection rendered per-piece detail table\n' >&2
  exit 1
fi
if [[ "$(grep -Fc '### mod' "$collapsed_projection_path")" -ne 2 ]]; then
  printf 'FAIL: collapsed projection did not render two moderator turns\n' >&2
  cat "$collapsed_projection_path" >&2
  exit 1
fi
if [[ "$(grep -Fc '### dotcursor' "$collapsed_projection_path")" -ne 2 ]]; then
  printf 'FAIL: collapsed projection did not render two dotcursor turns\n' >&2
  cat "$collapsed_projection_path" >&2
  exit 1
fi
grep -Fq 'ROUND-TWO-COLLAPSED' "$collapsed_projection_path"
grep -Fq 'discussion-pe-1' "$collapsed_projection_path"
grep -Fq 'discussion-pe-2' "$collapsed_projection_path"
grep -Fq 'Stale' "$collapsed_projection_path"
python3 - "$collapsed_projection_path" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
assert text.index('**State**') < text.index('**Participants**')
assert text.index('**Participants**') < text.index('**Table of contents**')
assert text.index('**Table of contents**') < text.index('## Discussion')
assert text.index('## Discussion') < text.index('**Projection metadata**')
assert text.index('projectionMode: `collapsed`') > text.index('**Projection metadata**')
PY

NO_MOD_TARGET="$RUN_DATE-synthesize-collapsed-no-mod"

"$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Synthesize Collapsed No Mod" >/dev/null
"$ROOT/commands/collab/engine/registry.py" join-participants "$NO_MOD_TARGET" pe --agent-id codex >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$NO_MOD_TARGET" turn-order pe --caller-role mod >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$NO_MOD_TARGET" active-phase Discussion --force --caller-role mod >/dev/null

no_mod_projection_path="$(python3 - "$REGISTRY" "$NO_MOD_TARGET" <<'PY'
import json
import sys
from pathlib import Path
registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
print(registry.parent / entry['transcriptPath'])
PY
)"

state="$("$ROOT/commands/collab/engine/registry.py" speak-state "$NO_MOD_TARGET" pe)"
revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["registryRevision"])' <<<"$state")"
cat >no-mod-pe.md <<'EOF'
STANCE: qualifies
Moderator-absent source unit.
EOF
"$ROOT/commands/collab/engine/registry.py" speak-render "$NO_MOD_TARGET" pe \
  --content-file no-mod-pe.md \
  --observed-revision "$revision" \
  --caller-role pe >/dev/null

state="$("$ROOT/commands/collab/engine/registry.py" synthesize-state "$NO_MOD_TARGET")"
revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["observedRevision"])' <<<"$state")"
cat >no-mod-synthesis.md <<EOF
## Discussion — Round 1 synthesis

NO-MOD-COLLAPSED.

_Synthesized by sy/codex from registry revision $revision._
EOF
"$ROOT/commands/collab/engine/registry.py" synthesize "$NO_MOD_TARGET" \
  --observed-revision "$revision" \
  --content-file no-mod-synthesis.md \
  --agent-id codex >/dev/null

if grep -Fq '### mod' "$no_mod_projection_path"; then
  printf 'FAIL: moderator-absent collapsed projection rendered a mod block\n' >&2
  cat "$no_mod_projection_path" >&2
  exit 1
fi
if [[ "$(grep -Fc '### dotcursor' "$no_mod_projection_path")" -ne 1 ]]; then
  printf 'FAIL: moderator-absent collapsed projection did not render one dotcursor block\n' >&2
  cat "$no_mod_projection_path" >&2
  exit 1
fi
grep -Fq 'NO-MOD-COLLAPSED' "$no_mod_projection_path"

printf 'OK: synthesize renders full projection content, plain entities, stable anchors, and atomic output\n'
