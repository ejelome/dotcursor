#!/usr/bin/env bash
set -euo pipefail

# A success seal must not certify an execution commit that has been orphaned
# from HEAD by a rebase or re-commit. verificationSeal.stale does not catch this
# (the commit still exists; only its reachability changed), so a dedicated
# reachability gate rejects the success verdict. This is the external-repo trap
# behind the original failure: a seal certifying a commit a later rewrite dropped
# from the branch. Reachable commits pass; non-existent refs are left to the
# drift and git-state gates rather than reported as orphaned here.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
WORKREPO="$(mktemp -d)"
trap 'rm -rf "$WORKREPO"' EXIT

git -C "$WORKREPO" init -q
git -C "$WORKREPO" config user.email tester@example.com
git -C "$WORKREPO" config user.name tester
printf 'seed\n' >"$WORKREPO/foo.txt"
git -C "$WORKREPO" add foo.txt
git -C "$WORKREPO" -c commit.gpgsign=false commit -qm 'seed'
printf 'deliverable\n' >>"$WORKREPO/foo.txt"
git -C "$WORKREPO" add foo.txt
git -C "$WORKREPO" -c commit.gpgsign=false commit -qm 'deliverable'
ORPHAN="$(git -C "$WORKREPO" rev-parse HEAD)"
# Amend the deliverable commit: ORPHAN is dropped from history (orphaned) while
# foo.txt stays committed at the new tip, so the git-state gate would still pass.
git -C "$WORKREPO" -c commit.gpgsign=false commit --amend --no-edit -qm 'deliverable (amended)'
REACHABLE="$(git -C "$WORKREPO" rev-parse HEAD)"

python3 - "$ROOT" "$WORKREPO" "$ORPHAN" "$REACHABLE" <<'PY'
import sys
sys.path.insert(0, f"{sys.argv[1]}/tools/collab")
import registry as R

_, workrepo, orphan, reachable = sys.argv[1:5]

def entry_with(commit):
    return {
        'id': 'orphan-provenance-fixture',
        'workRepo': workrepo,
        'execution': {
            'pe': {
                'status': 'completed',
                'touchedPaths': ['foo.txt'],
                'commits': [commit],
            }
        },
    }

# Reachable commit (current tip): accepted.
R.assert_execution_commits_reachable(entry_with(reachable))

# Orphaned commit (exists but not an ancestor of HEAD): rejected.
try:
    R.assert_execution_commits_reachable(entry_with(orphan))
except SystemExit as exc:
    message = str(exc)
    assert 'SEAL-PROVENANCE' in message, f'unexpected abort message: {message}'
    assert orphan in message, f'orphaned commit missing from message: {message}'
else:
    raise AssertionError('orphaned execution commit was not rejected at success seal')

# Non-existent ref: not reported as orphaned (left to drift/git-state gates).
R.assert_execution_commits_reachable(entry_with('0' * 40))

# No commits recorded: nothing to check.
R.assert_execution_commits_reachable({'id': 'x', 'workRepo': workrepo, 'execution': {'pe': {'status': 'completed'}}})
PY

printf 'OK: success seal rejects execution commits orphaned from HEAD, accepts reachable, ignores non-existent\n'
