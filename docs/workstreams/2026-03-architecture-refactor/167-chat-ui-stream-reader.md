# 167 Chat UI Stream Reader

## Goal

Close the remaining middle-layer gap between:

- the pure `ChatUiStreamAccumulator` in `llm_dart_core`
- and the full `DefaultChatSession` runtime in `llm_dart_chat`

for consumers that already have a `Stream<ChatUiStreamChunk>` and only need a
lightweight projection helper.

## Short Answer

Add a lightweight reader in `llm_dart_chat`:

- `ChatUiStreamReader`
- `readChatUiStream(...)`
- `ChatUiStreamReadResult`

This helper sits:

- above `ChatUiStreamChunk`
- above the pure accumulator
- below `DefaultChatSession`

It gives non-session consumers a convenient middle layer without widening core
events or forcing them into the full chat-session runtime.

## Why This Helper Belongs In `llm_dart_chat`

The helper should not live in `llm_dart_core`.

`llm_dart_core` should keep owning:

- shared event and chunk models
- pure accumulation logic
- deterministic replay-safe projection

The reader helper adds runtime behavior:

- side-channel delivery for transient data parts
- step-finish observation
- final-message completion surface
- replaying emitted snapshots to late listeners

Those are still framework-neutral, but they are no longer pure model logic.

That makes `llm_dart_chat` the right home.

## Implemented Surface

The landed helper is intentionally small:

- `ChatUiStreamReader`
- `readChatUiStream(...)`
- `ChatUiStreamReadResult extends StreamView<ChatUiMessage>`

`ChatUiStreamReader` exposes the reusable stateful processor that:

- applies `ChatUiStreamChunk`
- can consume a chunk stream directly
- emits projected message snapshots
- emits `stepFinishStream`
- emits `transientDataParts`
- resolves a final `result`

`readChatUiStream(...)` is the convenience wrapper that creates a reader,
starts consumption, and returns `ChatUiStreamReadResult`.

`ChatUiStreamReadResult` exposes:

- the projected message snapshot stream itself
- `stepFinishStream`
- `transientDataParts`
- `Future<ChatUiMessage> result`
- convenience getters for `finishReason`, `isAborted`, and `abortReason`

This follows the same additive result-object direction already used elsewhere
in the repository.

## Why A Result Object Instead Of Callback-Heavy Design

The reference SDK exposes several callback-oriented UI stream helpers.

For Dart, a result-object shape is the better minimal default here:

- easier to compose with `await for`
- easier to test
- easier to combine with other streams
- avoids immediately freezing a callback lifecycle API we may want to keep
  narrow

Consumers can still build callbacks on top of:

- `stepFinishStream`
- `transientDataParts`
- `result`

without forcing those callbacks into the helper contract itself.

## What The Helper Does

`ChatUiStreamReader` / `readChatUiStream(...)`:

- consumes `Stream<ChatUiStreamChunk>`
- projects persistent chunks into `ChatUiMessage` snapshots
- emits one snapshot per non-transient chunk
- emits transient `DataUiPart` values through a separate side stream
- emits message snapshots on `StepFinishEvent`
- resolves a final message once the input stream completes

The helper also uses replaying output channels so consumers can subscribe to
the result streams after processing has already started without losing earlier
emissions.

`DefaultChatSession` now also reuses this same stateful reader instead of
maintaining a separate handwritten remote-chunk projection loop.

## What The Helper Does Not Do

The helper intentionally does **not** become a second session runtime.

It does not own:

- prompt history
- message submission
- regeneration
- tool execution
- approval orchestration
- reconnect handling
- persistence
- transport request policy
- retry policy

Those remain in `DefaultChatSession` or higher app code.

## Relationship To `ChatUiStreamAccumulator`

`ChatUiStreamAccumulator` stays pure and reusable.

The new reader does not replace it.

Instead, it wraps the accumulator with just enough runtime behavior to make
direct chunk-stream consumption pleasant for:

- backend adapters
- custom clients
- Flutter integrations that do not want a full session object
- tests and demos that already have a chunk stream

## Relationship To `DefaultChatSession`

`DefaultChatSession` still owns the full chat lifecycle.

It now reuses `ChatUiStreamReader` for chunk projection, but the reader still
does not overlap with:

- chat state transitions
- prompt reconstruction
- auto tool continuation
- approval collection
- reconnect logic

So the boundary remains clean:

- reader = chunk stream in, message snapshots out
- session = full conversation runtime

## Why This Is Better Than Widening Core Events

The helper closes the usability gap that previously tempted us to add more core
event families.

We do not need to widen `TextStreamEvent` or `ChatUiStreamChunk` to make
non-session consumption easier.

Instead, we add a better runtime helper at the correct layer.

## Follow-Up Questions

The helper does not settle every future UI-runtime question.

Possible later follow-ups:

- whether a dedicated callback facade is worth adding on top of the result
  object
- whether the reader should later expose a typed final summary object instead
  of just `result` plus convenience getters
- whether HTTP or server adapters want a tiny adapter around this helper

Those should be evaluated later from real usage, not assumed now.

## Conclusion

This gap is now closed in a narrow way:

- `llm_dart_core` stays pure
- `llm_dart_chat` now has the missing middle helper
- `DefaultChatSession` stays the full orchestration path
- no new core event vocabulary was needed
