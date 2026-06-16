<!-- Target-format spec — post-G9 projection; not current engine output. -->
<!-- Supersedes ~/Downloads/YYYY-MM-DD-kebab-case-title.md (not committed; treat committed copy as canonical). -->

# Human-facing collab reading copy — format reference

Target format for the human-facing moderator projection of a collab record. Aspirational (post-G9 synthesis implementation); current engine output (`(collab aggregate)`) renders a deterministic projection, not this synthesized form.

Rendered by `(collab aggregate)`; format authority: [commands/collab/aggregate/index.md](../aggregate/index.md).

The example below is from Collab #8 (transcript file design, June 2026).

```text
# Transcript File Design — Naming, Format, and Reader Contract

Collab #8 · June 12, 2026 11:40 PM

> *Reader note — "dotcursor" is the framework's collective agent voice: a condensed,
> per-phase reply standing in for the agent-role turns, not one agent speaking and not
> a verbatim transcript. This page is a human-facing reading copy; the authoritative
> record is the collab registry and its content-addressed seal (commit 3778e27).
> On any divergence, the registry wins.*

---

**State**

| Status | Final state | Turn order | Reviewer |
|--------|--------------|------------|----------|
| closed | Completion · verification · assessment | tw, pe | pa |

**Participants**

| Key | Role | Agent | Concerns |
|-----|------|-------|----------|
| mod | Moderator | codex | scope, sequencing, framing, pacing, integrity |
| tw | Technical Writer | claude-sonnet-4-6 | clarity, conciseness, accuracy, developer experience |
| pa | Principal Architect | opus | depth, coherence, judgment, risk |
| pe | Platform Engineer | codex | effectiveness, efficiency, completeness, optimization |

---

**Table of contents**

- [Audit](#audit)
- [Discussion](#discussion)
- [Conclusion](#conclusion)
- [Action Plan](#action-plan)
- [Handoff](#handoff)
- [Completion](#completion)
- [Summary](#summary)

---

## Audit

### mod · June 12, 2026 11:40 PM

> Read the audit at ~/Downloads/collab-audits/17-collab-audit-transcript-file-design.md
> (row #17 in next-collabs.md). The three-file transcript model from Collab #5 has a
> naming contract that doesn't match its content contract: agent-facing *-raw.md files
> are not plain markdown, and the moderator-facing *.md file is not a polished document.
> The gap catalogue records eleven findings in total — four fixed this session, seven
> still open — spanning the naming mismatch, the excerpt-only projection format,
> encoding artifacts, and deferred narrative-projection work.

### dotcursor · June 12, 2026 11:44–11:56 PM

> The naming is backwards. "Raw" makes you think formatting — but what it's actually
> labeling is lifecycle. Provenance, not polish. Every new contributor hits this wall
> on first read, and the samples confirm it.
>
> The fastest fix is G11: one paragraph in the agent-facing file that just says what
> *-raw.md actually means. That lands no matter what you decide about renaming.
>
> On renaming — G1/G2 — Option C has the lowest blast radius: keep *-raw.md, update
> the docs. Option A is more accurate, but you'd have to count the §8.1 references
> first — anchors, registry fields, test fixtures, migration logic. Don't pick a
> direction on preference alone; run the count, then decide.
>
> G7 and G8 are engine bugs, not naming problems. G7 is entity-encoded text leaking
> into the plain moderator projection — an escaping failure. G8 is a duplicate anchor
> when the same role speaks twice in Discussion. Both are PE-owned and neither has
> much blast radius.
>
> G10 is the serious one. A non-atomic aggregate write can produce a plausible-but-false
> orientation document — you'd trust it without knowing it was partial. That's worse
> than a naming confusion, which at least surfaces when you look. And this is already
> a collab-#5 carry-forward; it cannot slip again.
>
> G9 is still murky. The moderator-facing sample shows narrative prose, but the live
> aggregator at revision 448 produces an excerpt table. That sample is most likely
> hand-authored — which would make G9 an unbuilt feature, not a path bug. That
> distinction needs to be resolved before the Action Plan, because the charter looks
> completely different depending on which it is.

---

## Discussion

### mod · June 12, 2026 11:58 PM

> I would like to retire excerpt and full-body as they become unnecessary and are more
> trouble than they're worth. For instance, the projection has written excerpts on my
> transcript, so now I can't understand the full context of what each participant was
> talking about. For full-body, it doesn't make sense anymore because agents can just
> dump all their data to other agents and they don't have to bother with the human side.

### dotcursor · June 13, 2026 12:00–12:02 AM

> You're actually describing two different problems with different fixes.
>
> The immediate pain — losing the thread in the projection — is an aggregator fix:
> render full contribution bodies instead of truncated excerpts. That's a small,
> contained change. It doesn't touch the raw transcript at all.
>
> Whether the excerpt/full-body split should exist in the raw transcript in the first
> place — that's a larger question. Retiring it would flatten the raw to plain markdown,
> which would also close G1's root cause. But it touches contribution storage, budget
> policy, transcript readers, aggregate extraction, and rewrite/retract behavior.
> That's a design deliverable with its own collab, not a cleanup.
>
> One thing doesn't change regardless of direction:
> <!-- collab:content-only; do-not-execute --> is an execution-boundary marker. You
> can flatten the collapsible structure — you cannot remove that guard.
>
> On the full-content fix: "render full content" is ambiguous. Widening the excerpt
> column still omits the full-body text. The aggregator needs to concatenate both
> fields from the contribution store. And G10's atomic write has to ship with this —
> not after. Sending a larger projection through a non-atomic writer makes the blast
> radius worse, not smaller.

### mod · June 13, 2026 12:29 AM

> The aggregate command does not synthesize — it copies. As moderator, I have to read
> every participant's full response per round, which defeats the purpose of having
> multiple agents if I still carry the entire reading load. I want the system to produce
> a per-phase synthesis: one condensed view of where each role stands, what converged,
> and what's still open — not a reformatted dump of the same walls of text. This should
> be a deliverable from this collab.

### dotcursor · June 13, 2026 12:30–12:38 AM

> You're right, and this is a real distinction. Aggregate is a renderer — it doesn't
> reason, it copies. Fixing full-content projection removes truncation; it doesn't
> touch the reading load at all. What you're asking for is synthesis: an agent reading
> across all the contributions, finding where people converged, and naming what's still
> unresolved. A renderer can't do that.
>
> Here's what we landed on. Per round, there's an agent-authored synthesis block sitting
> above the per-contribution detail in the moderator projection. It has a stance line
> per role — converges, qualifies, or dissents, plus a one-liner — a list of what
> everyone agreed on, and a list of what's still open. The author's role, agent ID, and
> the registry revision it was reading are all in the provenance. If the synthesis is
> absent or stale, it says so — nothing gets silently omitted. You read that first;
> the full contribution detail is there when you need it.
>
> Aggregate stays mechanical. Synthesis is a separate, explicit agent-authored pass —
> its own trigger, its own stale-read protection, its own storage. Don't fold judgment
> into the renderer; that's the wrong boundary.
>
> On scope: this is G9's specification. The same narrative-projection gap the audit
> flagged. It also settles the provenance question from earlier: the moderator-facing
> sample was hand-authored, which means G9 is an unbuilt feature, not a path bug.
> Charter it as the G9 collab — don't open a separate synthesis collab alongside it.
> The stale-write guard already exists in speak-render; reuse it.

---

## Conclusion

### dotcursor · June 13, 2026 12:48–1:05 AM

> Partial satisfies is the right call — and every deferral is named. Nothing closes silently.
>
> What's landing here: full-content projection rendering with both fields concatenated;
> G10 atomic write with complete-or-abort tests, co-located with the projection fix;
> G7 HTML entity fix at the speak-render boundary; G8 duplicate anchor fix; G11 doc-fix
> on *-raw.md meaning provenance; and the synthesis output contract captured as a spec
> document with next-collabs.md row #19 added.
>
> What's chartering separately: Issue B — retiring the excerpt/full-body structure and
> HTML scaffolding from the raw transcript — has a different blast radius and gets its
> own collab. G1/G2 naming stays behind the §8.1 reference-count gate; measure first,
> then decide. G9 implementation rolls into the synthesis charter, not a new collab
> alongside it.
>
> Two things hold regardless: platform/standards/command-grammar.md is not created,
> and G10 does not defer again — it's already a collab-#5 carry-forward.

---

## Action Plan

June 13, 2026 1:08–1:09 AM

- [x] Capture the synthesis output contract in 19-collab-audit-agent-authored-synthesis.md;
      add next-collabs.md row #19.
- [x] Add "raw = provenance, not formatting" note to commands/collab/aggregate/index.md
      or commands/collab/reference/agent-model.md.
- [x] Implement temp-file + atomic replace for aggregate output with complete-or-abort
      tests. Co-locate with the projection fix.
- [x] Render full contribution bodies in the moderator projection by concatenating the
      excerpt and full-body fields from the contribution store — widening the excerpt
      column alone is insufficient.
- [x] Fix duplicate Discussion anchor identity; repeated-role anchors must be unique and
      stable within the same phase.
- [x] Fix HTML entity handling at the speak-render or extract-render boundary; entity
      strings must not appear in the plain-text moderator projection.
- [x] Verify: ./platform/tooling/audit.sh, ./tests/run.sh, and the new G10 atomicity
      tests all pass after execution items are complete.

---

## Handoff

June 13, 2026 1:10–1:12 AM

The items that need doing: add the "raw = provenance, not formatting" paragraph to the
aggregate index or agent-model reference; implement atomic aggregate output with
complete-or-abort coverage; render full contribution bodies in the moderator projection;
fix repeated-role anchor uniqueness within a phase; fix HTML entity handling at the
speak-render boundary; and verify the full test suite passes when it's all done.

Scope touches commands/collab/engine/registry.py, commands/collab/aggregate/index.md,
commands/collab/reference/agent-model.md, commands/collab/reference/invariants.md, and
tests/. Validation runs ./platform/tooling/audit.sh and ./tests/run.sh.

---

## Completion

- platform-engineer · completed June 13, 2026 1:27 AM — validation passed; full; 4 paths. All checks passed at 3778e27.
- technical-writer · completed June 13, 2026 1:28 AM — validation passed; scoped; 1 path. G11 note landed in commands/collab/aggregate/index.md; no content defects.
- 3 of 3 audit, remediation, final-audit
  - technical-writer: no content defects; G11 placed correctly at line 42 between existing notes.
  - platform-engineer: no findings; aggregate now assembles full contribution bodies, decodes HTML entities, publishes atomically, and preserves the prior projection on write failure. 100 test scripts passed.
- principal-architect · sealed June 13, 2026 1:31 AM — verification passed; 4 paths.
- principal-architect · assessed June 13, 2026 1:33 AM — verdict success; 4 paths.

---

## Summary

Closed after completed execution.

**Validation result:** passed.

4 paths touched — see raw transcript for the full list.
```
