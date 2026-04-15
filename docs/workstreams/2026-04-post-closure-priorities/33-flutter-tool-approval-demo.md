# 33 Flutter Tool Approval Demo

## Why This Note Exists

The backend-hint demos proved that the current Flutter/session split is enough
for basic chat screens, but one important UI question still deserved a real
widget-level check:

- can a Flutter screen drive provider approval and local tool execution with
  the current session surface?

This slice answers that question with a small `MaterialApp` demo and a widget
test.

## Scope

This slice adds:

- `packages/llm_dart_flutter/example/tool_approval_demo_support.dart`
- `packages/llm_dart_flutter/example/flutter_tool_approval_demo.dart`
- `packages/llm_dart_flutter/test/flutter_tool_approval_demo_test.dart`

It also updates the package and example guides so this interaction path is
discoverable.

## Demo Shape

The example intentionally stays thin and uses existing surfaces only:

1. `ChatController` mirrors a `DefaultChatSession`
2. `DirectChatTransport` streams one provider-executed tool call that requests
   approval
3. the same turn also streams one local tool call that waits for client output
4. the UI responds with `respondToolApproval(...)`
5. the UI later resolves the local tool through `addToolOutput(...)`
6. the assistant finishes normally without any new event family or widget API

The important state path is:

- `awaitingApproval`
- `awaitingTool`
- `ready`

## What This Revalidates

This demo revalidates several frozen architecture decisions:

- `llm_dart_core` already has the right stable event and UI-part surface for
  approval requests
- `llm_dart_chat` already owns the correct orchestration APIs for manual tool
  continuation
- `llm_dart_flutter` does not need a shared widget toolkit to support this
  interaction class

## Why This Matters

This is the strongest practical check we can do before even considering any
new Flutter convenience helpers. If a real widget screen can already:

- render pending tool state
- render approval state
- trigger approval responses
- inject local tool output
- continue to a final assistant answer

then the current architecture is still holding.

## Bottom Line

Flutter now has a concrete tool/approval UI example and regression test, and
that result supports keeping the current event and session boundaries frozen.
