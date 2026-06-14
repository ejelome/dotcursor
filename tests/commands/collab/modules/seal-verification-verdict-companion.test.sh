#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

python3 - "$ROOT" <<'PY'
import sys

root = sys.argv[1]
sys.path.insert(0, root)

from commands.collab.engine import seal_verification as sv

entry = {
    'id': '2026-06-10-verdict-test',
    'verificationSeal': {
        'observedRevision': 11,
        'executionSignature': 'execution-digest-1',
        'contentDigest': 'content-digest-1',
        'pathDigests': {'tools/a.py': {'mode': '100644', 'blob': 'a' * 40}},
        'sealedAt': '2026-06-10T18:00:00+02:00',
        'sealedBy': 'pa',
        'stale': False,
    },
    'verdict': {'outcome': 'success'},
}

companion = sv.build_seal_verdict_companion(entry)
assert companion['authoritative'] is False
assert companion['authority'] == 'verificationSeal'
assert companion['closeGate'] == 'verificationSeal'
assert companion['observedRevision'] == 11
assert companion['executionDigest'] == 'execution-digest-1'
assert companion['contentDigest'] == 'content-digest-1'
assert sv.seal_verdict_companion_status(entry, companion)['current'] is True

for key, value in (
    ('observedRevision', 10),
    ('executionDigest', 'execution-digest-2'),
    ('contentDigest', 'content-digest-2'),
    ('pathDigests', {'tools/a.py': {'mode': '100644', 'blob': 'b' * 40}}),
    ('verdict', {'outcome': 'failed'}),
):
    edited = dict(companion)
    edited[key] = value
    status = sv.seal_verdict_companion_status(entry, edited)
    assert status['current'] is False, (key, status)
    assert 'mismatch' in status['reason'], status

assert sv.seal_verdict_companion_status(entry, None)['current'] is False

try:
    sv.build_seal_verdict_companion({'id': 'missing-seal'})
except SystemExit as exc:
    assert 'requires verificationSeal' in str(exc)
else:
    raise AssertionError('companion built without verificationSeal')

print('OK: seal-verdict companion is non-authoritative and digest-bound')
PY
