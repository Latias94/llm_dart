# Remaining Boundary Fearless Refactor — Milestones

Status: Complete
Last updated: 2026-05-27

## M0 — Scope And Evidence Freeze

Status: Complete on 2026-05-27.

Exit criteria:

- Workstream docs exist and agree.
- Candidate order is explicit.
- Existing closed core seam refactor is treated as authority, not reopened.

## M1 — Provider Codec Contract

Status: Complete on 2026-05-27.

Exit criteria:

- A reusable provider codec contract runner exists, or the no-op decision is
  documented with deletion-test evidence.
- Provider-specific codecs remain provider-owned.
- At least OpenAI and Anthropic fixture contracts are covered or explicitly
  deferred.

Primary gates:

```powershell
dart --suppress-analytics test packages/llm_dart_openai/test/openai_fixture_contract_test.dart packages/llm_dart_anthropic/test/anthropic_fixture_contract_test.dart
dart --suppress-analytics run tool/check_workspace_dependency_guards.dart
```

## M2 — Capability Descriptor Enforcement

Status: Complete on 2026-05-27.

Exit criteria:

- A runtime/app capability gate consumes provider descriptors.
- Descriptive/inferred capabilities are not treated as hard guarantees.
- Tests cover supported, unsupported, and inferred provider shapes.

## M3 — Non-Text App Request Seams

Status: Complete on 2026-05-27.

Exit criteria:

- Each non-text capability is classified as deep request seam, adapter-only, or
  no-op with rationale.
- Any new request Module hides validation/projection complexity.
- App docs explain the chosen surface.

## M4 — Chat Turn And Transport Protocol

Status: Complete on 2026-05-27.

Exit criteria:

- Turn ordering, replay, resume, cancellation, and stream error recovery have
  clearer locality, or the current Modules are explicitly retained.
- Chat input remains app-facing and does not leak provider prompt contracts.
- HTTP transport protocol tests cover the chosen Interface.

## M5 — Provider Options Policy

Status: Complete on 2026-05-27.

Exit criteria:

- OpenAI-family option policy is easier to navigate and test.
- Typed provider options remain provider-owned.
- Compatibility warnings stay precise.

## M6 — Serialization Registry Decision

Status: Complete on 2026-05-27.

Exit criteria:

- Registry implementation exists only if it passes the deletion test.
- Otherwise, explicit codec families are documented as the deliberate deep
  Interface.
- Schema version and error diagnostics remain clear.

## M7 — Closeout

Status: Complete on 2026-05-27.

Exit criteria:

- All tasks are done, rejected, or split.
- Fresh final gates are recorded.
- `WORKSTREAM.json` status is updated.
- `HANDOFF.md` contains next action and residual risk.
