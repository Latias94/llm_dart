# Flutter Tool Orchestration Boundary

## Goal

This note freezes the remaining tool-result orchestration rule for
`llm_dart_flutter`.

The unresolved question was not whether tool output injection belongs in the
Flutter session layer. That was already settled.

The unresolved question was:

> When should a chat session continue the next assistant turn after tool input,
> tool output, and approval responses are collected?

This matters because `repo-ref/ai` separates:

- shared model stream semantics
- UI/session orchestration rules such as automatic continuation after tool
  completion

`llm_dart` should keep the same separation, but with a Dart-specific session API.

## Frozen Conclusion

Tool continuation is a session concern, not a shared core event concern.

The session must not continue after the first individual tool update when the
current assistant step still has unresolved work.

Recommended rule:

- keep `TextStreamEvent` unchanged
- keep `ToolCallEvent`, `ToolResultEvent`, `ToolApprovalRequestEvent`, and
  `ToolOutputDeniedEvent` as the shared model semantics
- let `DefaultChatSession` decide when the current assistant step is complete
  enough to continue

## Step-Completion Rule

For the current assistant step:

- if any client-executed tool still waits for local output, stay in
  `awaitingTool`
- if any tool still waits for approval, stay in `awaitingApproval`
- only continue the next assistant turn after the remaining unresolved tool or
  approval state has been cleared

This is the same architectural lesson as `repo-ref/ai`
`lastAssistantMessageIsCompleteWithToolCalls`, but it stays inside the Dart
session layer instead of becoming a new core abstraction.

## What This Changes In Practice

### Client-Executed Tools

If one assistant step emits multiple client-executed tool calls:

- the UI may provide tool output one call at a time
- the session updates the visible tool part immediately
- the session does not continue until all pending client-executed tool calls in
  that step have a final local output

This avoids an incorrect extra round-trip after only the first completed tool.

### Provider-Executed Approval Flows

If a provider-executed tool has been approved:

- the approval response is still written into prompt history immediately
- the session should continue the provider-backed turn only after the current
  step no longer has unresolved approvals or client-side tool output work

This matters for mixed steps such as:

- one provider-executed tool that requires approval
- one client-executed tool that still waits for local output

Approving the provider tool alone is not enough to resume the step yet.

### Mixed Approval Outcomes

If a step contains several provider-executed approvals:

- a later denied response must not block continuation if an earlier approved
  provider-executed tool still needs the follow-up request
- continuation is therefore decided from the whole step state, not only from
  the last approval click

## Why This Boundary Is Better

This keeps responsibilities honest:

- `llm_dart_core` models tool semantics
- `llm_dart_chat` models chat-session orchestration
- `llm_dart_flutter` adds Flutter-specific adapters above that runtime
- provider packages keep owning provider-native tool wire details

It also matches how Flutter applications actually behave:

- the UI renders one assistant message with several tool cards
- user interaction may resolve them gradually
- the next request should only start once the current step is ready

## Future Convenience Work

This freeze does not require a hooks-style API like `repo-ref/ai`.

If the repository later adds convenience helpers such as automatic local tool
callbacks, those helpers should still live in `llm_dart_chat` above the
current session boundary, with any Flutter-specific wrappers staying in
`llm_dart_flutter`.

They should not widen:

- `TextStreamEvent`
- the shared prompt/tool-definition model
- the provider packages
