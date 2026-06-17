# (collab synthesize)

Generate an agent-authored per-phase synthesis block, store it as a typed artifact bound to the current source unit, and make it available to the moderator projection above per-contribution detail.

## Trigger

**Dispatch:** `(collab synthesize [<target>])` — routing-only command form; not a shell command.
**Search phrases:** collab synthesize, per-phase synthesis, agent synthesis, phase synthesis block, moderator synthesis

## Steps

1. Read [invariants.md](../reference/invariants.md) before executing; call the relevant helper fresh and do not trust prior reads from conversation context (Invariant #4). Resolve the target collab with **Registry targeting** in **Notes**.
<!-- abort: synthesize-record-unreadable -->
2. Read the resolved registry. If unreadable, **ABORT** (agent-honor-system): record unreadable; name the path.
<!-- abort: synthesize-closed -->
3. If the registry status is `closed` or `archived`, **ABORT** (agent-honor-system): record is closed or archived; synthesis requires an active collab.
<!-- abort: synthesize-completion-phase -->
4. Resolve the active phase from registry `activePhase`. If missing, **ABORT** (agent-honor-system): active phase missing in metadata. If the active phase is `Completion`, **ABORT** (agent-honor-system): synthesis is not available in the `Completion` phase.
<!-- abort: synthesize-no-contributions -->
5. Call `commands/collab/engine/registry.py synthesize-state <target>` to resolve the synthesis source unit: `phase`, `roundStartAnchor`, `contributionAnchors`, `observedRevision`, and `roundNumber` (1-based count of existing synthesis artifacts for the current phase plus one). If the output reports `noContributions: true`, **ABORT** (agent-honor-system): no contributions in the active phase; synthesis requires at least one contribution anchor.
6. Read each contribution listed in `contributionAnchors` from the contribution store. This is the authoritative synthesis input — do not parse `records/<slug>-raw.md` bytes as input (Invariant #4).
7. Generate the synthesis block per the **Output contract** in **Notes**: role-stance table, converged items, open items, action-plan deltas, and provenance footer. The heading is `## <Phase> — Round <N> synthesis` where `<N>` is the `roundNumber` returned by Step 5. Write the block to a temporary content file.
8. Call `commands/collab/engine/registry.py synthesize <target> --observed-revision <observedRevision> --content-file <path>` to validate the observed revision against the live registry and store the synthesis artifact. If the live revision differs from `observedRevision`, the helper aborts before writing and emits `RESUME: commands/collab/engine/registry.py synthesize-state <target>` — re-run Step 5 before proceeding.
9. Report the synthesis block, round number, and artifact ID returned by the helper.
10. Stop.

## Notes

- **Parameters:** target collab slug, id, or numeric `#N` as the first token after `synthesize`; when absent, resolved per **Registry targeting** in **Notes**.
<!-- abort: synthesize-registry-target -->
- **Registry targeting:** Resolve the target collab from the resolved registry, using `commands/collab/engine/registry.py` as the shared helper. When the first token after the route is present, treat it as a collab slug, id, or stable numeric position. Otherwise use `activeCollabId`. If the registry is unreadable or invalid, the token does not match any entry, or `activeCollabId` is empty, **ABORT** (agent-honor-system): registry target unavailable; name the registry field or token.
- **Round-label:** The synthesis heading uses `Round <N>` where `<N>` is the 1-based count of synthesis artifacts stored for the current phase. The first `(collab synthesize)` call for a phase produces `Round 1`; each subsequent call produces `Round 2`, `Round 3`, and so on. The round number is derived by the helper from the stored artifact count — no first-class registry round counter is required. The final heading form is `## <Phase> — Round <N> synthesis`.
- **Output contract:** The synthesis block structure is specified in `19-synthesis-spec.md` §5.2. Content sections:
  - `**Role stances**` — table with Role, Stance, and Summary columns; one row per contributing role.
  - `**Converged**` — list of items all roles agreed on this round.
  - `**Open**` — list of unresolved or disputed items.
  - `**Action-plan deltas**` _(if any)_ — items flagged as Action Plan candidates.
  - Footer line: `_Synthesized by <agentId> at registry revision <N>. Source anchors: <anchor list>._`
- **Voice register:** Write synthesis in collective first person ("we," "here's what we landed on"), not as a per-role summary where each contributor's stance is listed individually. See the collab #8 register in `commands/collab/reference/transcript-template.md`. Register is doc-only enforced; no tooling check exists or is warranted — synthesis voice is a stylistic convention, not a structural invariant.
- **Synthesis identity:** The author role for synthesis attribution is `sy`. `sy` is not a participant role, not a deterministic projector (`dp`), and not an alias for `aggregate`. The `sy` identity is generative and lives outside `commands/collab/reference/projectors/`. Identity record: [`synthesizers/sy.json`](../reference/synthesizers/sy.json). See `synthesize-charter-constraints.md` §Synthesis identity.
- **Source unit:** The synthesis source unit is the ordered set of visible contribution anchors in the active phase since the last `roundStartAnchor` (the anchor of the last moderator contribution in the phase before the current round of participant contributions, or `null` for the initial round before any moderator speaks in a phase). The persisted anchor set is the authoritative source-unit identity; it is not a derived counter. See `19-synthesis-spec.md` §5.1 and §6.8.
- **Freshness binding:** Every synthesis artifact binds `observedRevision`, `phase`, `roundStartAnchor`, `contributionAnchors`, `authorRole`, and `agentId`. Any write that changes the phase, contribution set, or anchor set — `speak`, `rewrite speak`, `retract speak`, `advance`, `restore` when they alter the phase, contribution set, or anchor set — makes prior synthesis stale. See `synthesize-charter-constraints.md` §Freshness binding.
- **Stale synthesis:** When a synthesis artifact's `observedRevision` or `contributionAnchors` differ from current registry state, the moderator projection renders the stale block as: `_Stale — produced at revision [M]; current revision [N]. Re-run (collab synthesize) to update._` Stale synthesis is never silently reused or omitted. See `19-synthesis-spec.md` §5.5.
- **Absent synthesis:** When no synthesis artifact exists for the current phase round, the moderator projection renders a placeholder: `_Not yet produced. Run (collab synthesize) to generate._` See `19-synthesis-spec.md` §5.6.
- **Projection placement:** In `per-piece` mode, the synthesis block is placed above the inline detail table in the moderator projection — the moderator reads the synthesis block first and uses the contribution detail for verification. In `collapsed` mode, no inline detail table follows; the reading-copy blocks with raw-reference links are the complete projected output for that round. See `19-synthesis-spec.md` §5.3.
- **Non-lifecycle:** `(collab synthesize)` does not advance lifecycle state, constitute a participant turn, or satisfy a phase gate. It writes a typed synthesis artifact only. Phase transitions are driven by `speak-lifecycle`; synthesis is a view operation.
- **Projection mode:** Set via `(collab set projection.mode collapsed | per-piece)`; default is `collapsed`. Collapsed renders one `dotcursor` reading-copy block per stored synthesis artifact (one per moderator-led round; one for the whole phase when no moderator speaks). Per-piece renders the synthesis block above the inline detail table. Controls projection rendering only — does not affect synthesis artifact storage.
- **Reader note (collapsed):** Collapsed projection emits a framing note before phase content identifying `dotcursor` as the collective agent voice and naming the registry as the authoritative record. This note is part of the target format — it is what makes the page read as one voice — and is wired by the renderer, not authored in the synthesis artifact. Canonical text (collab-specific commit SHA omitted; renderer substitutes the seal commit when available): `> *Reader note — "dotcursor" is the framework's collective agent voice: a condensed, per-phase reply standing in for the agent-role turns, not one agent speaking and not a verbatim transcript. This page is a human-facing reading copy; the authoritative record is the collab registry and its content-addressed seal. On any divergence, the registry wins.*`
- **Storage contract:** The synthesis artifact body is stored outside the registry body and outside the raw transcript. The registry holds only pointers, digests, and synthesis metadata (round number, artifact ID, source unit, staleness state). Long-form synthesis content must not enter registry bytes or projection-only files. See `synthesize-charter-constraints.md` §Shared deterministic layer.
- **Stale-write guard:** `commands/collab/engine/registry.py synthesize` requires `--observed-revision` from the immediately preceding `synthesize-state` call. If the live registry revision differs, the helper aborts before writing and emits a `RESUME:` advisory — the same guard pattern as `speak-render`. See `19-synthesis-spec.md` §5.5.
- **See also:** [`19-synthesis-spec.md`](../reference/19-synthesis-spec.md) — synthesis deliverable contract; [`synthesize-charter-constraints.md`](../reference/synthesize-charter-constraints.md) — charter constraints and supersession record; [`invariants.md`](../reference/invariants.md) — Invariants #4, #17; [`handoff-shape.md`](../reference/handoff-shape.md) — writeScope and validationCommands contract.

```route-arg
dispatch: (collab synthesize [<target>])
param: name=<target>; required=optional; placeholder=<target>; class=dynamic; rule=collab slug, id, or numeric #N; default=literal:activeCollabId
```
