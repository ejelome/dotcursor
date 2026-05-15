# Collab project identity contract

The checked-in project identity file (`.collab-project.json`) binds a repository to its collab state root. This contract governs the file schema, the `projectId` binding rules, and the state-root resolver's behavior.

## Identity file

`.collab-project.json` is placed at the repository root and tracked in version control.

| Field | Type | Description |
| --- | --- | --- |
| `schemaVersion` | integer | Schema revision; currently `1`. |
| `projectId` | string | Opaque identifier. Never derived from directory name, path, remote URL, basename, or worktree. Set once at project initialization; never changed. |
| `label` | string | Human-readable project name; used for display only, not resolution. |
| `state.mode` | string | Worktree sharing mode: `"shared"` (default) or `"isolated"`. |
| `state.isolation` | string | Isolation opt-in policy: `"opt-in"` means isolation requires explicit configuration per worktree. |

## Identity properties

**Opaque.** `projectId` is an opaque string; tooling must not derive or infer it from path, basename, remote URL, or worktree location.

**History-bound.** The id follows git history. A renamed or forked repository carries the same id and resolves to the same state root. Path changes, remote changes, and clone operations do not change the id.

**Stable.** `projectId` is written once at initialization and never changed, even when `label` is updated or the repository is moved.

## State root

The resolver maps `projectId` → `$HOME/.collabs/<projectId>/`. The `$HOME` expansion happens at runtime; the absolute path is not stored in the repo.

| Path under state root | Description |
| --- | --- |
| `registry.json` | Registry backing all collab routes. |
| `records/` | Transcript files (`*.md`). |

## Worktree behavior

The default mode is `"shared"`: all worktrees of a repository resolve to the same state root and share `registry.json` and `records/`. A worktree may opt into isolation explicitly (`state.mode: "isolated"`); no per-worktree root is created automatically. The isolation opt-in is scoped to the worktree configuration and does not change the identity file.

## Transition stub

For repositories that held existing `.collabs/` records before this contract was in place, migration leaves a transitional stub at `.collabs/project.json`. The stub contains only `{ "schemaVersion": 1, "projectId": "<id>" }` — no resolved absolute path — so the resolver remains authoritative if the home directory moves.

The stub is gitignored and may be lost to `git clean -Xdf`; primary collab state at `$HOME/.collabs/<projectId>/` is outside the repository tree and is unaffected. The stub is retired when the resolver reads `.collab-project.json` directly for all worktrees; at that point `.collabs/project.json` may be removed.

New repositories that initialize after this contract is in place start without a stub; they use `.collab-project.json` exclusively.
