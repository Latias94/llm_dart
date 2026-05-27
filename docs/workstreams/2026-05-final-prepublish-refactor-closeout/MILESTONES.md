# Final Prepublish Refactor Closeout — Milestones

Status: Complete
Last updated: 2026-05-27

## M0 — Open Lane

Status: Complete on 2026-05-27.

Exit criteria:

- Workstream docs exist.
- The four requested refactors are task-ledger slices.
- Scope excludes public-surface expansion and publishing.

## M1 — Context And ADR Index

Status: Complete on 2026-05-27.

Exit criteria:

- `CONTEXT.md` records project vocabulary and frozen seams.
- `docs/adr/` contains an index and ADRs for the decisions most likely to be
  re-litigated.
- No new architecture decision contradicts release ledger posture.

## M2 — Runtime Event / Tool Loop Closeout

Status: Complete on 2026-05-27.

Exit criteria:

- Runtime event/tool-loop workstream state matches its implementation evidence.
- Any remaining work is split as post-publish follow-on, not release blocker.
- Release ledger remains consistent.

## M3 — Provider Test-Only Implementation Kit

Status: Complete on 2026-05-27.

Exit criteria:

- Repeated fixture contract assertion logic has a test-only Module.
- Provider-native request/stream behavior remains provider-owned.
- Targeted provider fixture tests pass.

## M4 — Scenario-Family Test Split

Status: Complete on 2026-05-27.

Exit criteria:

- At least one highest-risk giant test bucket is split by scenario family.
- Production code is unchanged unless required by test-only support.
- Targeted scenario tests pass.

## M5 — Closeout

Status: Complete on 2026-05-27.

Exit criteria:

- All tasks are completed, explicitly rejected, or split.
- Fresh release gates are recorded.
- Workstream status and release ledger agree.
- A commit records the final prepublish state.
