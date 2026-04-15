# 34 Flutter Paused Tool State Restore

## Why This Note Exists

The first Flutter tool/approval demo proved that the UI could drive the manual
tool loop directly, but one more real integration question remained:

- can a Flutter app save and restore a paused chat controller while the session
  is still waiting for approval or local tool output?

This slice extends the existing tool/approval demo to answer that question.

## Scope

This slice extends:

- `packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart`
- `packages/llm_dart_flutter/example/tool_approval_demo_support.dart`
- `packages/llm_dart_flutter/test/flutter_tool_approval_demo_test.dart`

It also updates the package and workstream docs to make this restore story
explicit.

## What The Demo Now Validates

The same widget-level demo now supports:

1. sending a message that pauses in `awaitingApproval`
2. saving a snapshot through `ChatPersistenceAdapter.saveController(...)`
3. rebuilding a new `ChatController` through `restoreController(...)`
4. continuing approval from the restored controller
5. pausing again in `awaitingTool`
6. restoring that paused local-tool state as well
7. completing the turn without any special restore-only API

## Why This Matters

This is a high-signal revalidation of the current layering:

- snapshot encoding already belongs in `llm_dart_chat`
- controller restoration convenience already belongs in `llm_dart_flutter`
- paused tool and approval continuation already works through the normal
  `respondToolApproval(...)` and `addToolOutput(...)` APIs

No new Flutter-specific restore protocol was necessary.

## Bottom Line

Flutter now has widget-level proof that `awaitingApproval` and `awaitingTool`
states can survive controller persistence and restoration using the current
snapshot surface, which further supports keeping the architecture frozen.
