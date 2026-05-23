# Restructure Migration Plan

Corrected pilot sequence for migrating the command tree from the flat `commands/<ns>.md` layout to the directory-per-command `commands/<ns>/index.md` layout.

## Pilot Sequence

### Step 1 — Run topology and flag-scope validators

Run `tools/command-system/audit-topology.sh` and `tools/command-system/audit-flag-scope.sh` against the current tree. Both must pass before any structural changes begin.

Flag collisions without an explicit `override: <parent-scope> — <reason>` declaration are errors. Resolve all errors before proceeding.

### Step 2 — Run placement audit

Run `tools/command-system/audit-placement.sh`. Files referenced by more than one command in a namespace must move to `core/<ns>/` before namespace moves begin.

### Step 3 — Move shared files to `core/collab/`

Create `core/collab/` and move all files identified in step 2 as cross-command shared material for the `collab` namespace.

The unprefixed `core/` directory is created here only if cross-namespace material exists. Do not create `core/` speculatively.

### Step 4 — Run catalog gate

Run `./tools/command-system/sync-commands-catalog.sh --check` to confirm the commands catalog is fresh before the first namespace move.

This gate is a **precondition** for the pilot move. It must pass before step 5.

### Step 5 — Pilot move: one namespace/command pair

Move one namespace and one of its commands to the `index.md` layout:

- `commands/<ns>.md` → `commands/<ns>/index.md`
- `_functions/<ns>/<cmd>.md` content inline → `commands/<ns>/<cmd>/index.md`

After the move, re-run `sync-commands-catalog.sh` (write mode) to regenerate the catalog for the new structure.

### Step 6 — Test suite

Run the test suite scoped to the pilot namespace:

- `audit-topology.sh --migration` passes — confirms both that every generated catalog link resolves and that the moved namespace topology is valid; run once after step 5 to satisfy both guarantees
- Every inherited flag origin resolves — run `audit-flag-scope.sh`; it checks that each override declaration references an existing flag at the declared parent scope; the full effective-flag resolver (computing every inherited flag a command sees and proving each resolves to its declaring scope) is deferred until the first flag-bearing route migration

Resolve any failures in both criteria before proceeding to bulk moves.

### Step 7 — Bulk moves

Remaining namespaces are mechanical repeats of steps 4–6 (catalog gate → move → test). Each namespace is moved and validated independently before the next begins.

`audit-placement.sh --migration` (step 2) is a fixed pre-pilot gate and does not repeat per bulk namespace. If a future namespace acquires new cross-command shared material between bulk iterations, run a one-time placement re-run at that point rather than embedding the validator in every bulk pass.

## Correction Note

The original Conclusion pilot sequence listed the catalog gate as step 5 (after the pilot move at step 4). This was incorrect: the catalog gate is a precondition for the first namespace move, not a follow-on check. The corrected order above places the catalog gate at step 4, before the pilot move at step 5.
