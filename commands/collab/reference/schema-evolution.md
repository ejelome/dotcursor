# Schema evolution

## Trigger

**Slash:** (reference only — not an invocable route)
**Prose dispatch:** (reference only — not an invocable route)
**Search phrases:** schema evolution, field lifecycle, unknown fields preserved, field retirement, registry field classification

## Steps

1. Read this document when adding, renaming, or retiring a field in `registry.json` or in any helper-output JSON.
2. Do not mutate registry or transcript state from this documentation-only reference.

## Notes

The file is the canonical owner of registry field lifecycle rules. Both `registry.schema.json` (load-time validation) and any load-time validation note in `commands/collab/engine/registry.py` must link to this file rather than restating the rules inline.

### Field classification

**Known fields** are fields whose names and types are declared in `registry.schema.json`. A known field with the wrong type or an out-of-range value is **rejected** at load time; the helper exits with a structured error naming the field and constraint.

**Unknown fields** are fields not declared in `registry.schema.json`. An unknown field at any schema depth — top-level, inside a collab entry, or inside a nested lifecycle object — is **preserved unchanged** through every mutating operation. Unknown fields must survive a load-validate-write cycle without modification. The rule is the "unknown fields preserved" contract; breaking the rule is a breaking schema change regardless of field name.

The preserved-unknown rule applies to:
- Top-level registry fields other than those declared in the schema
- Fields inside a collab entry object
- Fields inside nested lifecycle objects (e.g., `execution`, `verdict`, `handoff`)

### Malformed-rejected / unknown-preserved rule

One rule, two cases:

| Field type | Behavior |
|---|---|
| Known, wrong type or invalid value | **Rejected** at load time |
| Unknown (not in schema) | **Preserved** through load-validate-write |

The implementation contract: `registry.schema.json` validation must be applied on load, before any mutation, and the schema validator must not strip unknown fields. A closed-schema validator that silently drops unknown keys violates the preserved-unknown contract.

### Required round-trip test shape

Every commit that adds or modifies schema validation must include same-commit tests covering both cases:

1. **Malformed-known rejection:** Inject a wrong type into a declared known field (e.g., `revision: "string"` instead of an integer). Assert that the helper exits with a non-zero status and names the field.
2. **Unknown-field round-trip:** Inject an unknown field at each of the three depths (top-level, collab entry, nested lifecycle). Run a mutating helper operation. Assert the unknown field is present and unchanged in the output registry.

Tests for case 2 must cover all three depths in the same commit; partial coverage (top-level only) does not satisfy the round-trip test requirement.

### Counter lifecycle

The registry uses two distinct counters with non-overlapping roles:

**`revision`** — write-guard counter. Stored as the top-level `revision` field in `registry.json`. Incremented by `bump_registry_revision()` on every registry write. The stale-write guard (`speak-render`, `execute`) reads this field to detect concurrent writes. This field must not be renamed unless the rename is atomic across: the stored field name, every read site in `commands/collab/engine/registry.py`, and all helper-output labels that reference it.

**`registryRevision`** — helper-output presentation label. This name appears in `speak-state` and similar helper JSON output as a human-readable label sourced from the `revision` field (`registry.py:229`). The label is not an independently stored counter. The label may be retired or renamed in a future collab without touching the stored `revision` field.

**`eventIndex`** — log sequence counter. A new counter to be introduced with the append-only revision writer (`<state-root>/revisions/`). Increments only on explicit registry log events. Header rewrites, transcript rendering, and state repair must not increment `eventIndex` unless they deliberately emit a registry log event.

### Field-retirement records

| Field | Last known value | Retired in | Retirement reason |
|---|---|---|---|
| `registryRevision` (top-level in `registry.json`) | `1552` | collab #52 `collab-state-observability` | Vestigial. The `revision` field became the canonical write-guard counter; `registryRevision` was never updated after the rename and no read path consulted it. |

**Seal-evidence sub-key `registryRevision`:** The seal-evidence object uses `registryRevision` as a sub-key (`registry.py:1238`, `:5560`) to record the registry revision at seal time. The sub-key is sourced from the `revision` field (not from the retired top-level `registryRevision`). The sub-key is retained as a named evidence anchor; its source must remain `revision`.

**`retire_legacy_registry_fields()` stripper** (`registry_io.py:92`): Retained to strip residual top-level `registryRevision` from registries that predate the rename. No retirement condition is stated. See **Legacy artifact retirement ledger** below.

### Legacy artifact retirement ledger

Tracks retained legacy artifacts that are outside the registry field lifecycle. The field-retirement table above covers registry-field removals; this table covers legacy code paths, role files, and reader patterns retained for backward compatibility.

| Artifact | Location | Retention reason | Retirement condition | Status |
|---|---|---|---|---|
| `dp.json` role tombstone | `commands/collab/reference/roles/dp.json` | Historical participant rendering still has a source-level contract in `tests/commands/collab/registry.py/projector-metadata-nonjoinable.test.sh`; removing the tombstone without retiring that contract breaks the historical renderer even when no live registry references `dp` | Delete only in the same change that removes or rewrites the historical participant-rendering contract and verifies no active, closed, archived, or test fixture registry entry references `dp` as a participant | Tracked — no live `~/.collabs/**/registry.json` reference found, but the source contract remains active |
| `retire_legacy_registry_fields()` stripper | `commands/collab/engine/registry_io.py:92`; invoked in `load_registry()` and `save_registry()` | Strips residual top-level `registryRevision` from registries that predate the rename | Delete when a repository-owned fixture sweep and user-scope registry sweep both show no top-level `registryRevision` key, and `validate_registry()` rejects that key before any load/save compatibility path can observe it | Tracked — no live `~/.collabs/**/registry.json` top-level `registryRevision` key found; source fixtures and validator posture still need a paired retirement change |
| `LEGACY_EXPANDED_RE`, `LEGACY_HEADING_RE` patterns | `commands/collab/engine/transcript_readers.py`, lines 13-14; used as fallback in `transcript_roles_for_phase()` | Matches legacy transcript contribution headings (`**role —` bold-expanded and `### role —` heading formats) that predate the current `<details><summary>role</summary>` shape | Delete when `grep -rP '^\*\*[A-Za-z0-9_-]+ —|^### [A-Za-z0-9_-]+ —' ~/.collabs/dotcursor/records/` returns empty and no test fixture depends on either pattern | Retained — live transcript matches remain in `~/.collabs/dotcursor/records/2026-06-29-coding-principles.md` |
| `legacy-baseline` event wrapping | `commands/collab/engine/registry_io.py`, lines 195-217 (`ensure_legacy_revision_baselines`); sentinel check in `commands/collab/engine/registry_core.py` | Synthesizes a `legacy-baseline.json` sentinel for collabs that predate the revision event journal; `restore --to` rejects events with `eventType == "legacy-baseline"` as non-restorable | Delete when every collab entry in each reachable registry has at least one proper non-baseline revision event in its event directory and no `legacy-baseline.json` files remain under the corresponding revision roots | Retained — live `~/.collabs/dotcursor/revisions/*/legacy-baseline.json` files remain |
