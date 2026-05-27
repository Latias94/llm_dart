# Pre-Release Boundary Freeze — Milestones

Status: Complete
Last updated: 2026-05-27

## M0 — Scope And Evidence Freeze

Status: Complete on 2026-05-27.

Exit criteria:

- Workstream docs exist and agree.
- The five requested deliverables are task-ledger items.
- Broad runtime/provider rewrites are out of scope.

## M1 — Release Ledger

Status: Complete on 2026-05-27.

Exit criteria:

- A release ledger exists.
- A guard validates release/workstream state consistency.
- Publish blockers and known deferrals are explicit.

## M2 — Provider Fixture Coverage

Status: Complete on 2026-05-27.

Exit criteria:

- At least one missing release-committed provider surface gains fixture
  contract coverage, or the no-op is documented.
- The fixture runner remains test-only.
- No live provider credentials or network calls are required.

## M3 — App Facade Export Contract Freeze

Status: Complete on 2026-05-27.

Exit criteria:

- App/root facade exported symbols are classified in a manifest.
- A guard detects accidental export drift.
- No late release-cycle symbol removal is required.

## M4 — HTTP Chat Transport Protocol Freeze

Status: Complete on 2026-05-27.

Exit criteria:

- v1/v2 HTTP transport compatibility policy is release-facing.
- Tests cover supported protocol version, downgrade, and reconnect guarantees.
- Local runtime hooks remain rejected on HTTP transport.

## M5 — OpenAI Responses Projection Family Index

Status: Complete on 2026-05-27.

Exit criteria:

- OpenAI Responses native projection families have a package-private ownership
  index.
- The index does not become a runtime registry.
- Existing Responses codec and stream tests remain green.

## M6 — Closeout

Status: Complete on 2026-05-27.

Exit criteria:

- All tasks are done, rejected, or split.
- Fresh final gates are recorded.
- `WORKSTREAM.json` status is updated.
- `HANDOFF.md` contains publish blockers and post-alpha follow-ons.
