# Milestones

Status: Closed on 2026-05-23 after M1 through M5 were completed and verified.

## M1 - Ownership Audit Complete

Exit criteria:

- Every current provider option symbol has an ownership classification.
- Public contract versus implementation support is explicit.
- The first split has a confirmed validation target.

## M2 - Bag Transport Split Complete

Exit criteria:

- JSON bag behavior is isolated.
- Existing provider bag tests pass unchanged.
- `foundation.dart` remains the intentional public seam.

## M3 - Typed Invocation Split Complete

Exit criteria:

- typed provider invocation options and bag projection are isolated from bag
  transport implementation details.
- wrong-type and wrong-provider option rejection behavior stays stable.

## M4 - Prompt/Tool/Replay Split Complete

Exit criteria:

- prompt-part, tool, and replay option contracts are no longer buried behind
  invocation option implementation details.
- serialization and replay metadata tests pass.

## M5 - Workstream Ready To Close

Exit criteria:

- provider package analysis passes.
- provider package tests pass.
- guards pass.
- evidence and handoff docs identify any remaining follow-on decisions.
