# Local Tool Execution Convenience

## Goal

This note freezes where local client-side tool execution convenience should live
after the basic session and tool-state machinery landed.

The remaining question was:

> Should `llm_dart` grow shared execute-style tool APIs in `core`, or should
> automatic local tool execution stay a Flutter/session-layer convenience?

## Frozen Conclusion

Automatic local tool execution should stay in `llm_dart_chat`.

That means:

- `llm_dart_core` keeps only tool declaration and replay semantics
- provider packages keep only provider request/response adaptation
- `llm_dart_chat` may add convenience callbacks such as `onToolCall` that
  observe a client-executed tool call and optionally return local output

## Why This Boundary Is Better

The shared core only knows:

- declared function tools
- tool-call and tool-result semantics
- approval and replay semantics

It does not know:

- how a Flutter app wants to resolve local tools
- whether the app wants to auto-run or manually approve a local tool
- whether the app wants to enrich the UI while the local tool is running

Those are session and application concerns.

If we moved execute-style callbacks into `core`, the shared model layer would
start owning application orchestration instead of stable model semantics.

## Recommended Convenience Shape

The current convenience direction is:

- `DefaultChatSession` may accept an `onToolCall` callback
- `DefaultChatSession` may also accept a `ToolExecutionRegistry` as the common
  name-based convenience form
- the callback receives the stable local tool-call payload from the latest
  assistant message
- the callback may return a local tool output or a local tool error result
- the session turns that result into the same `addToolOutput` path used by
  manual callers

This keeps one consistent continuation path.

## Typed JSON Input Convenience

The session-layer convenience may also include a small typed decode helper for
the common "tool input is a JSON object" case.

That means `llm_dart_chat` may provide:

- `ToolExecutionRequest.requireJsonObjectInput()`
- `ToolExecutionRequest.decodeJsonObjectInput(...)`
- `ToolExecutionRegistry.withJsonHandler(...)`

This convenience is intentionally narrow.

It is useful because many local tools want:

- a stable `toolName -> handler` registry
- a small decode step from `Map<String, Object?>` into an app-owned input type
- a predictable way to turn malformed tool input into tool error output

It should not become:

- a full schema validation framework
- a provider capability contract
- a new shared abstraction in `llm_dart_core`

The important rule is that decode failures stay inside the same local tool
execution path. By default, malformed input should become tool error output,
not a chat-session crash.

## Important Rules

### 1. Reuse The Existing Tool Output Path

Automatic local tool execution must not invent a second continuation protocol.

It should reuse:

- `ToolUiPart`
- `ToolOutputUpdate`
- prompt-history tool result persistence
- the existing step-completion continuation rule

### 2. Do Not Auto-Run Provider-Executed Tools

Provider-executed tools remain provider-owned even when the UI renders them.

The Flutter convenience callback should only target client-executed tools.

### 3. Callback Failures Are Tool Failures, Not Session Crashes

If a local tool callback throws:

- do not convert that into a generic chat-session error state
- convert it into a tool error result for the current tool call

This keeps malformed provider streams, transport failures, and local tool
execution failures clearly separated.

### 4. Approval Still Gates Local Execution

If a client-executed tool needs approval:

- do not invoke the convenience callback before approval
- invoke it only after the approval response moves the tool back into the
  local-output pending state

## Comparison With `repo-ref/ai`

The reference implementation exposes `onToolCall` in its chat layer, not in the
provider spec.

That is the correct lesson to copy.

The part we do not need to copy directly is its exact React-oriented shape.

For Dart and Flutter, the more useful rule is:

- keep the convenience local
- keep the continuation path unified
- keep the shared core provider-agnostic
- allow a registry-shaped convenience wrapper for the common
  `toolName -> handler` case instead of forcing every app to hand-write
  callback dispatch logic
