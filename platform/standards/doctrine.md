# Platform Design Doctrine

Per-design rules that have been deliberated and converged through the collab process. Each entry is a binding ruling, not a guideline; a departure requires a new collab or an explicit supersession note.

---

## Explicit values in records

**Explicit values in records.** Opinionated defaults are a write-time convenience, not a read-time contract. Every resolved default must be stamped into the record at write time and read directly from the stored field — never re-derived from its absence via `.get(key, DEFAULT_*)` or `value if key in object else DEFAULT_*`. Records that carry `createdAt` must declare the field; records without `createdAt` are grandfathered. A lint rule forbids both `.get(<default-key>, DEFAULT_*)` and `... if <key> in <object> else DEFAULT_*` in engine code. Open-roster effort is exempt because it is matrix-resolved advisory state from `agent-effort.json`, not state owned by an individual registry record. `registry.schema.json` is reference/projection only; a parity gate asserts that the schema-declared field set matches the live validator's enforced set.

**Source:** collab `2026-06-09-explicit-values-no-implicit-defaults` (directive: "the principle that values should be explicit"; convergence: 2026-06-09)
