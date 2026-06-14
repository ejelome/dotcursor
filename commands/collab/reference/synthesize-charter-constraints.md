# Synthesize charter constraints

This document is the implementation-charter companion to
[`19-synthesis-spec.md`](19-synthesis-spec.md). It records the platform
constraints that the future `(collab synthesize)` charter must preserve before
the public `(collab aggregate)` route can be retired.

## Durable source precondition

The source specification for the charter is
`commands/collab/reference/19-synthesis-spec.md`. Before implementation begins,
the charter must verify that this file is reachable from the checked-in tree and
contains:

- the 18 finding catalogue entries;
- the output contract in section 5, including role stances, convergence, open
  items, action-plan deltas, placement, provenance, and absent/stale states;
- the stale-read contract in section 5.5;
- the source-unit definition in sections 5.1 and 6.8;
- the architect sequencing judgments in section 7;
- the section 10 action-item list.

Section 10 item 2 is a sequencing `[precondition]`. Do not regress it to
`[design]`: if a future source-unit question is non-executable design
exploration, keep it out of Action Plan instead.

## Projection parity gate

`(collab synthesize)` must reach projection parity before `(collab aggregate)`
is removed. Parity means synthesize owns the moderator-facing projection surface
that aggregate currently protects:

- header and status metadata;
- participant contribution detail beneath the synthesis block;
- source anchors for every rendered contribution;
- projection source revision, source digest, and contribution-store digest;
- no raw-transcript parsing for projection data;
- complete-or-absent output writes.

The aggregate projection tests are the parity oracle. At minimum, the charter
must port or retarget:

- `tests/commands/collab/aggregate-transcript.test.sh`;
- `tests/commands/collab/registry.py/aggregate-projection-output.test.sh`.

The public aggregate route is retired only after synthesize passes the parity
oracle. Route retirement is a separate change from initial synthesize delivery.

## Shared deterministic layer

Synthesize may be generative, but the projection assembly layer remains
deterministic infrastructure. Keep the existing lower-layer machinery for
registry reads, contribution-store reads, anchor rendering, digest rendering,
and atomic output. Do not rebuild those mechanics inside the generative command.

`(collab aggregate)` can be deleted after parity, but the deterministic
projection functions it relies on stay available as shared lower-layer code.

## Synthesis identity

`dp` is a deterministic projector identity. Do not rename it blindly to `sy`.
The `sy` identity, if introduced, is generative and must live outside
`commands/collab/reference/projectors/`.

The charter must audit existing `dp` references before deleting `dp.json` or
changing role prose. Deterministic projection may become unnamed infrastructure;
`sy` is the accountable synthesis author, not a projector alias.

## Freshness binding

Every synthesis artifact must bind to the exact source it summarizes:

- observed registry revision;
- source digest;
- contribution-store digest;
- phase;
- source-anchor set;
- author role;
- agent ID.

Any mutation that touches the bound source phase makes the prior synthesis
stale. This includes `speak`, `rewrite speak`, `retract speak`, `advance`, and
`restore` when they change the phase, contribution set, or anchor set. Stale
synthesis must be labeled visibly in the projection; it must not be silently
reused or silently regenerated.

## Boundary

The synthesize charter is one projection charter for synthesis/G9. Do not fold
raw-transcript filename migration, Issue B raw-plane changes, or unrelated
transcript-file work into it.
