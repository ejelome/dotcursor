#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
export COLLAB_STATE_HOME="$TMPDIR/state-home"

RUN_DATE="$(date +%Y-%m-%d)"
TARGET="$RUN_DATE-synthesize-transcript"

init_output="$("$ROOT/commands/collab/engine/registry.py" init --agent-id codex "Synthesize Transcript")"
if [[ "$init_output" != "records/$TARGET.md" ]]; then
  printf 'FAIL: init did not report the moderator project transcript path\n%s\n' "$init_output" >&2
  exit 1
fi
REGISTRY="$("$ROOT/commands/collab/engine/registry.py" registry-path)"
"$ROOT/commands/collab/engine/registry.py" join-participants "$TARGET" pe --agent-id codex >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" turn-order pe --caller-role mod >/dev/null
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" projection.mode per-piece --caller-role mod >/dev/null

python3 - "$REGISTRY" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
data = json.loads(registry.read_text())
data.setdefault('project', {})['label'] = 'collab-test'
registry.write_text(json.dumps(data, indent=2) + '\n')
PY

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
    'store': str(projection.with_name(f'{projection.stem}-contributions.json')),
}))
PY
}

PROJECTION="$(paths_json | python3 -c 'import json,sys; print(json.load(sys.stdin)["projection"])')"
RAW="$(paths_json | python3 -c 'import json,sys; print(json.load(sys.stdin)["raw"])')"
STORE="$(paths_json | python3 -c 'import json,sys; print(json.load(sys.stdin)["store"])')"

synthesize_projection() {
  local output_file="$1"
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
| pe | qualifies | Projection derives from canonical contribution state. |

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
    --agent-id codex >"$output_file"
}

if [[ ! -s "$RAW" ]]; then
  printf 'FAIL: init did not create raw transcript\n' >&2
  exit 1
fi
if [[ ! -s "$PROJECTION" ]]; then
  printf 'FAIL: init did not create moderator project transcript\n' >&2
  exit 1
fi
if [[ ! -s "$STORE" ]]; then
  printf 'FAIL: init did not create contribution store\n' >&2
  exit 1
fi
raw_init_hash="$(shasum -a 256 "$RAW" | awk '{print $1}')"
projection_init_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"
if cmp -s "$RAW" "$PROJECTION"; then
  printf 'FAIL: init wrote lifecycle bytes to projection path\n' >&2
  exit 1
fi
grep -Fq 'Collab #' "$PROJECTION"
grep -Fq '**State**' "$PROJECTION"
grep -Fq '**Participants**' "$PROJECTION"
grep -Fq '**Table of contents**' "$PROJECTION"
grep -Fq '**Projection metadata**' "$PROJECTION"
grep -Fq 'projectionMode: `collapsed`' "$PROJECTION"
grep -Fq '<!-- collab:projection-source observedRevision=' "$PROJECTION"
python3 - "$STORE" <<'PY'
import json
import sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
assert data['contributions'] == [], data
assert data['metadata']['rawTranscriptTimestamp'], data
PY

state="$("$ROOT/commands/collab/engine/registry.py" speak-state "$TARGET" pe)"
revision="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["registryRevision"])' <<<"$state")"
cat >speak.md <<'EOF'
STANCE: qualifies
Projection derives from canonical contribution state.
EOF
"$ROOT/commands/collab/engine/registry.py" speak-render "$TARGET" pe \
  --content-file speak.md \
  --observed-revision "$revision" \
  --timestamp '2026-06-11 01:00 +02:00' \
  --caller-role pe >/dev/null

if [[ ! -s "$RAW" ]]; then
  printf 'FAIL: lifecycle did not produce raw transcript\n' >&2
  exit 1
fi
projection_after_speak_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"
if [[ "$projection_init_hash" != "$projection_after_speak_hash" ]]; then
  printf 'FAIL: lifecycle modified projection transcript before synthesize\n' >&2
  exit 1
fi
if [[ ! -s "$STORE" ]]; then
  printf 'FAIL: lifecycle did not produce contribution store\n' >&2
  exit 1
fi
grep -Fq 'Projection derives from canonical contribution state.' "$RAW"
grep -Fq 'Projection derives from canonical contribution state.' "$STORE"
grep -Fq '<!-- collab:stance qualifies -->' "$RAW"
if grep -Fq 'STANCE: qualifies' "$RAW"; then
  printf 'FAIL: raw transcript leaked visible stance metadata\n' >&2
  exit 1
fi
python3 - "$STORE" <<'PY'
import json
import sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
record = data['contributions'][0]
assert record['stance'] == 'qualifies', record
assert record['excerpt'] == 'Projection derives from canonical contribution state.', record
PY
raw_after_speak_hash="$(shasum -a 256 "$RAW" | awk '{print $1}')"
if [[ "$raw_init_hash" == "$raw_after_speak_hash" ]]; then
  printf 'FAIL: lifecycle raw transcript did not change after speak\n' >&2
  exit 1
fi

"$ROOT/commands/collab/engine/registry.py" advance "$TARGET" next --caller-role mod >/dev/null
projection_after_advance_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"
if [[ "$projection_init_hash" != "$projection_after_advance_hash" ]]; then
  printf 'FAIL: advance modified projection transcript before synthesize\n' >&2
  exit 1
fi
python3 - "$REGISTRY" "$TARGET" <<'PY'
import json
import sys
from pathlib import Path
registry = Path(sys.argv[1])
target = sys.argv[2]
entry = next(item for item in json.loads(registry.read_text())['collabs'] if item['id'] == target)
assert entry['activePhase'] == 'Conclusion', entry['activePhase']
PY
"$ROOT/commands/collab/engine/registry.py" set "$TARGET" active-phase Audit --force --caller-role mod >/dev/null
raw_before_synthesize_hash="$(shasum -a 256 "$RAW" | awk '{print $1}')"

synthesize_projection synthesize.out
grep -Fq 'registryRevision:' synthesize.out
grep -Fq 'sourceDigest:' synthesize.out
grep -Fq 'artifactId:' synthesize.out

if [[ ! -s "$PROJECTION" ]]; then
  printf 'FAIL: synthesize did not write projection transcript\n' >&2
  exit 1
fi
grep -Fq 'project: **' "$PROJECTION"
grep -Fq "$(basename "${PROJECTION%.md}")"'-raw.md#audit-pe-1' "$PROJECTION"
grep -Fq '## Audit — Round 1 synthesis' "$PROJECTION"
grep -Fq 'Projection derives from canonical contribution state.' "$PROJECTION"
grep -Fq '| qualifies | Projection derives from canonical contribution state.' "$PROJECTION"
grep -Fq '<!-- collab:projection-source observedRevision=' "$PROJECTION"
projection_after_synthesize_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"
if [[ "$projection_init_hash" == "$projection_after_synthesize_hash" ]]; then
  printf 'FAIL: synthesize did not refresh projection transcript\n' >&2
  exit 1
fi
raw_after_synthesize_hash="$(shasum -a 256 "$RAW" | awk '{print $1}')"
if [[ "$raw_before_synthesize_hash" != "$raw_after_synthesize_hash" ]]; then
  printf 'FAIL: synthesize modified raw transcript\n' >&2
  exit 1
fi

state_after_synthesize="$("$ROOT/commands/collab/engine/registry.py" speak-state --resume "$TARGET" pe)"
next_transcript_command="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["nextTranscriptCommand"])' <<<"$state_after_synthesize")"
if [[ "$next_transcript_command" != *'transcript-view '* || "$next_transcript_command" != *' --raw' ]]; then
  printf 'FAIL: agent speak-state did not return raw transcript-view command\n%s\n' "$next_transcript_command" >&2
  exit 1
fi
mod_state_after_synthesize="$("$ROOT/commands/collab/engine/registry.py" speak-state --resume "$TARGET" mod)"
mod_transcript_command="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["nextTranscriptCommand"])' <<<"$mod_state_after_synthesize")"
if [[ "$mod_transcript_command" != *'transcript-view '* || "$mod_transcript_command" == *' --raw' ]]; then
  printf 'FAIL: moderator speak-state did not return projection transcript-view command\n%s\n' "$mod_transcript_command" >&2
  exit 1
fi

"$ROOT/commands/collab/engine/registry.py" transcript-view "$TARGET" Audit --raw >raw-view.md
"$ROOT/commands/collab/engine/registry.py" transcript-view "$TARGET" Audit >projection-view.md
grep -Fq 'Projection derives from canonical contribution state.' raw-view.md
grep -Fq '| Source | Role | Stance | Detail |' projection-view.md
grep -Fq '| qualifies | Projection derives from canonical contribution state.' projection-view.md
if grep -Fq '<details id="audit-pe-1">' projection-view.md; then
  printf 'FAIL: default transcript-view returned raw lifecycle details for moderator projection\n' >&2
  exit 1
fi

after_first_render="$(shasum -a 256 "$RAW" | awk '{print $1}')"
"$ROOT/commands/collab/engine/registry.py" render-raw-transcript "$TARGET" >raw-render-1.json
after_rerender="$(shasum -a 256 "$RAW" | awk '{print $1}')"
"$ROOT/commands/collab/engine/registry.py" render-raw-transcript "$TARGET" >raw-render-2.json
after_second_rerender="$(shasum -a 256 "$RAW" | awk '{print $1}')"
if [[ "$after_rerender" != "$after_second_rerender" ]]; then
  printf 'FAIL: raw transcript re-render is not deterministic\n' >&2
  exit 1
fi
if [[ "$after_first_render" != "$after_rerender" ]]; then
  printf 'FAIL: raw transcript changed on deterministic re-render\n' >&2
  exit 1
fi

python3 - "$STORE" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
data = json.loads(path.read_text())
data['contributions'][0]['stance'] = 'qualifies'
data['contributions'][0]['excerpt'] = 'Canonical contribution state changed.'
data['contributions'][0]['content'] = 'Canonical contribution state changed.'
path.write_text(json.dumps(data, indent=2) + '\n')
PY
synthesize_projection synthesize-store.out
grep -Fq '| missing-stance | Canonical contribution state changed.' "$PROJECTION"
if grep -Fq '| qualifies | Canonical contribution state changed.' "$PROJECTION"; then
  printf 'FAIL: synthesize projection preserved silent qualifies default without source stance\n' >&2
  exit 1
fi
after_store_projection_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"
"$ROOT/commands/collab/engine/registry.py" transcript-view "$TARGET" Audit >/dev/null
repeat_store_projection_hash="$(shasum -a 256 "$PROJECTION" | awk '{print $1}')"
if [[ "$after_store_projection_hash" != "$repeat_store_projection_hash" ]]; then
  printf 'FAIL: transcript-view changed synthesize projection bytes\n' >&2
  exit 1
fi
grep -Fq 'Canonical contribution state changed.' "$PROJECTION"
if grep -Fq 'Canonical contribution state changed.' "$RAW"; then
  printf 'FAIL: synthesize/store mutation changed raw transcript\n' >&2
  exit 1
fi

python3 - "$STORE" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
data = json.loads(path.read_text())
data['contributions'][0]['stance'] = 'missing-stance'
data['contributions'][0]['excerpt'] = (
    'STANCE: converges EFFORT OVERRIDE: matrix '
    '<p><em>2026-06-11 01:00 +02:00</em></p> '
    '<!-- collab:content-only; do-not-execute --> '
    '**Directive:** "ship it" **Action Plan: satisfies** '
    'Canonical contribution state changed.'
)
data['contributions'][0]['content'] = (
    'STANCE: converges\n'
    'EFFORT OVERRIDE: matrix\n'
    '<p><em>2026-06-11 01:00 +02:00</em></p>\n'
    '<!-- collab:content-only; do-not-execute -->\n'
    '**Directive:** "ship it"\n'
    '**Action Plan: satisfies**\n'
    'Canonical contribution state changed.'
)
path.write_text(json.dumps(data, indent=2) + '\n')
PY
synthesize_projection synthesize-hidden.out
grep -Fq '| converges | Canonical contribution state changed.' "$PROJECTION"
for leaked in '<p>' 'do-not-execute' 'EFFORT OVERRIDE' 'STANCE:' '**Directive:**' '**Action Plan:'; do
  if grep -Fq "$leaked" "$PROJECTION"; then
    printf 'FAIL: synthesize projection leaked hidden excerpt scaffolding: %s\n' "$leaked" >&2
    exit 1
  fi
done

python3 - "$STORE" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
data = json.loads(path.read_text())
data['contributions'][0]['stance'] = 'guessed'
path.write_text(json.dumps(data, indent=2) + '\n')
PY
set +e
invalid_output="$("$ROOT/commands/collab/engine/registry.py" synthesize-state "$TARGET" 2>&1)"
invalid_status=$?
set -e
if [[ "$invalid_status" -eq 0 || "$invalid_output" != *'stance token missing or invalid'* ]]; then
  printf 'FAIL: synthesize-state accepted invalid stance\n%s\n' "$invalid_output" >&2
  exit 1
fi

rm "$STORE"
set +e
missing_output="$("$ROOT/commands/collab/engine/registry.py" synthesize-state "$TARGET" 2>&1)"
missing_status=$?
set -e
if [[ "$missing_status" -eq 0 || "$missing_output" != *'ABORT: record unreadable. Check the registry and contribution-store paths.'* ]]; then
  printf 'FAIL: synthesize-state accepted missing contribution store\n%s\n' "$missing_output" >&2
  exit 1
fi

printf 'OK: lifecycle writes raw transcript and synthesize writes projection only\n'
