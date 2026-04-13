# Read Chat UI Stream Facade Policy

## Purpose

This note closes the remaining question around the lightweight
`readChatUiStream(...)` helper:

- should it grow a callback facade or typed final-summary object now
- or should it stay on the current stream-plus-result contract

## Current Surface

The current helper already exposes a narrow but usable Dart-shaped contract:

- `Stream<ChatUiMessage>` through `ChatUiStreamReadResult` itself
- `stepFinishStream`
- `transientDataParts`
- `Future<ChatUiMessage> result`
- convenience futures for `finishReason`, `isAborted`, and `abortReason`

That means the helper already covers the main practical needs for non-session
consumers:

- incremental message projection
- final message access
- step-finish observation
- transient UI data observation
- final finish-state inspection

## What The Current Code Path Actually Shows

The current repository usage does not show pressure for another public facade.

Today:

- direct public uses of `readChatUiStream(...)` only exist in the focused
  helper tests
- `DefaultChatSession` reuses the underlying `ChatUiStreamReader` directly
  rather than needing a second callback-oriented wrapper
- the existing chat runtime already has its own richer lifecycle surface
  through session state streams, transport hooks, and prompt-history
  orchestration

So the open gap is currently theoretical, not usage-proven.

## Why A Callback Facade Is Not Worth Freezing Yet

Adding callback-first lifecycle APIs now would have weak justification.

It would mainly duplicate patterns that Dart callers can already express with:

- `await for`
- `stream.listen(...)`
- `result.then(...)`
- `stepFinishStream.listen(...)`
- `transientDataParts.listen(...)`

It would also force premature decisions about:

- callback ordering
- error propagation between stream and callback paths
- whether finish callbacks run before or after final metadata patches
- how callback APIs interact with cancellation, late listeners, and replayed
  stream outputs

Those details are exactly the kind of lifecycle surface that should only be
frozen under real integration pressure.

## Why A Typed Final-Summary Object Is Also Premature

The current helper already exposes the highest-value final summary fields in a
simple Dart form:

- `result`
- `finishReason`
- `isAborted`
- `abortReason`

Any richer final summary object would need to decide which of the following are
actually stable helper-level concerns:

- final message only
- finish metadata only
- step summaries
- transport metadata
- counts of transient parts
- future provider-specific final diagnostics

That is still too speculative for a helper that intentionally sits below the
full session runtime.

## Boundary Decision

`readChatUiStream(...)` should stay on the current result-object contract for
now.

The stable helper shape is:

- stream snapshots for persistent message state
- side streams for step-finish and transient data
- final message access through `result`
- a few convenience futures for finish-state inspection

This is enough for the current Dart-first and Flutter-first design.

## Reopen Threshold

This decision should only be revisited if at least two concrete integrations
show that the current contract is too indirect.

Valid pressure signals would look like:

- two independent Flutter integrations both building the same callback wrapper
- a backend adapter and a Flutter app both needing the same richer final
  summary object
- repeated user code that cannot be expressed cleanly with the current stream
  and future surfaces

Absent that kind of evidence, adding another public facade would mostly be API
noise.

## TODO Consequence

The workstream should therefore:

- close the open TODO about adding a callback facade or typed final-summary
  surface
- keep this as a future demand-driven policy question rather than an active
  refactor blocker

## Bottom Line

`readChatUiStream(...)` is already mature enough at its intended layer.

The right next move is not another helper wrapper.

The right next move is to keep the helper narrow and revisit only when real
integration pressure proves that streams plus `result` are no longer enough.
