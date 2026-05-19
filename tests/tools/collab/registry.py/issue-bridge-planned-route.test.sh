#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

python3 - "$ROOT" "$TMPDIR" <<'PY'
import importlib.util
import sys
from pathlib import Path

root = Path(sys.argv[1])
tmp = Path(sys.argv[2]) / 'issue-bridge-root'
sys.path.insert(0, str(root))
spec = importlib.util.spec_from_file_location('registry_under_test', root / 'tools/collab/registry.py')
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

def write(rel: str, text: str) -> None:
    path = tmp / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)

write('_functions/collab/export-issues.md', '# /collab export-issues\n')
write('commands/collab.md', '# /collab\n')
write('commands/commands.md', '# /commands\n')
write(
    '_functions/collab/_helper-output.md',
    '\n'.join([
        '## Abort families',
        'Each entry names the logical module.',
        'Full-body envelope rejection',
        'Paired-execution-signature double-increment guard',
        'seal-verification-archive-protocol-violation',
    ]),
)
write(
    'tests/tools/collab/registry.py/rebinding-invariants.test.sh',
    '\n'.join([
        '#!/usr/bin/env bash',
        '# projectId rebinding',
        '# agentId rebinding',
        '# issue bridge',
    ]),
)

try:
    module.validate_planned_route_prerequisites(tmp)
except SystemExit as exc:
    message = str(exc)
    assert 'third prerequisite: _functions/git/issue.md (output contract)' in message, message
    assert 'issue output contract' in message, message
    assert 'issue owner metadata' in message, message
    assert 'issue requires preservation' in message, message
    assert 'issue implement handoff shape' in message, message
else:
    raise AssertionError('planned route gate accepted missing /git issue contract')

write(
    '_functions/git/issue.md',
    '\n'.join([
        '## Notes',
        '- **Output contract:** Issue delivery: prefill or connector-backed.',
        '- **Owner metadata:** Preserve Owner.',
        '- **`_requires:` preservation:** Keep `_requires:`.',
        '- **Implement handoff shape:** structured input.',
    ]),
)
module.validate_planned_route_prerequisites(tmp)
PY

printf 'OK: issue bridge planned-route prerequisite gate holds\n'
