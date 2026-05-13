# M1 Boundary Decision Freeze

Date: 2026-05-13
Status: frozen

## Summary

M1 freezes the ownership model for the next breaking implementation line:

- provider packages will emit model-call events only
- `llm_dart_ai` will own full generation-run events
- `TextStreamEvent` stays the public runtime event name, but moves out of
  provider ownership
- provider model-call streaming gets a new provider-owned base name:
  `LanguageModelStreamEvent`
- chat direct transport will move to the AI runtime path instead of calling
  `LanguageModel.doStream(...)` directly

This is intentionally a naming and ownership freeze, not the full
implementation. The first implementation slice should create the new
provider/runtime seam with adapters before deleting old names.

## Final Names

### Provider Model-Call Stream

Final base name: `LanguageModelStreamEvent`.

Reasoning:

- it describes one provider/model invocation, not the entire app-facing text
  generation run
- it aligns with the provider contract name `LanguageModel`
- it leaves `TextStreamEvent` available for the user-facing runtime stream
- it avoids importing runtime language into provider packages

Provider event classes should describe provider/model facts:

- model-call start and warnings
- response metadata
- text, reasoning, file, source, custom, and raw chunks
- tool input streaming
- tool calls
- provider-executed tool results
- tool input errors
- model-call finish or error

Provider event classes must not describe:

- run start
- step start
- step finish
- run finish
- local tool execution start/end
- chat message lifecycle
- UI data parts

### AI Runtime Full Stream

Final base name: `TextStreamEvent`.

Reasoning:

- this is already the public name users see in runtime, chat, and UI
  projection APIs
- it matches the app-facing mental model: a text generation stream can include
  text, reasoning, tools, files, sources, lifecycle, and errors
- keeping the runtime name stable reduces migration noise while still fixing
  ownership

Runtime events may include:

- run start
- step start
- adapted provider/model-call content events
- tool execution lifecycle
- preliminary tool results
- tool approval request/response
- tool output denied
- step finish
- run finish
- abort
- error
- raw provider chunks when enabled

## Public Helper Freeze

`generateText(...)` and `streamText(...)` are the long-term app-facing runtime
helpers. They should no longer mean "single provider call" in the stable
surface.

`generateTextCall(...)` and `streamTextCall(...)` remain the long-term combined
text and structured-output result facades. They should delegate to the unified
runtime foundation instead of a separate thin provider-call helper path.

`GenerateTextRunner`, `StreamTextRunner`, `runTextGeneration(...)`, and
`streamTextRun(...)` are migration-era implementation shapes. They should
either become private runtime internals or temporary aliases over the unified
runtime result surface.

## Agent Decision

Do not introduce a public `Agent` / `ToolLoopAgent` abstraction in the first
code slice.

Rationale:

- the event split is the architectural blocker
- a public agent API would freeze more surface before the runtime result shape
  is proven
- chat can initially call `streamText(...)` and project the result to UI chunks
- an agent wrapper can be added later if it removes real duplication in chat,
  examples, or user code

Private/internal agent-like helpers are allowed if they make the runtime loop
cleaner, but they should not be exported during M2.

## Step Control Scope

The first implementation pass should keep `maxSteps` as the defensive guard
and add stop-condition types only when the unified runtime result foundation is
in place.

Frozen direction:

- keep `maxSteps` for hard safety
- later add composable stop conditions:
  - `isStepCount(int count)`
  - `isLoopFinished()`
  - `hasToolCall(String name)`
  - custom predicate over completed steps

This prevents the first code slice from mixing event ownership migration with
new loop policy features.

## Callback Vocabulary

The runtime callback vocabulary should be:

- `onStart`
- `onStepStart`
- `onLanguageModelCallStart`
- `onLanguageModelCallFinish`
- `onToolExecutionStart`
- `onToolExecutionFinish`
- `onChunk`
- `onStepFinish`
- `onFinish`
- `onAbort`
- `onError`

Rules:

- model-call callbacks are scoped to the provider invocation
- step callbacks are scoped to one runtime step, including model-call results
  and tool execution results
- tool callbacks are scoped to local runtime tool execution
- `onChunk` observes runtime stream events, not provider-only events

## `TextStreamEvent` Migration Story

Because this is still an alpha/breaking line, the migration can be direct, but
it should be staged to keep the code reviewable:

1. Add `LanguageModelStreamEvent` to `llm_dart_provider`.
2. Add the runtime-owned `TextStreamEvent` foundation to `llm_dart_ai`.
3. Add adapters between provider model-call events and runtime text stream
   events.
4. Move `LanguageModel.doStream(...)` to return provider model-call events.
5. Move public app-facing `streamText(...)` to return the runtime stream
   result.
6. Update chat direct transport to consume runtime UI projection.
7. Remove provider ownership of runtime lifecycle events.

Temporary aliases are allowed only inside the implementation window. They
should not be documented as stable public API.

## First Implementation Slice

Selected first code slice:

1. Add the provider-owned `LanguageModelStreamEvent` vocabulary next to the
   current provider stream events.
2. Add explicit docs/tests that providers may not emit run/step/chat lifecycle
   events.
3. Add an AI-runtime adapter layer that can convert provider model-call events
   into runtime `TextStreamEvent` values.
4. Do not update every provider codec in this first slice unless the adapter
   proves small enough.

The success criterion for the first slice is architectural traction, not full
migration. After it lands, the next slice can update `LanguageModel.doStream`
and focused providers against the new provider event type.

## Risks

- `TextStreamEvent` is heavily referenced in tests, provider codecs, chat, UI,
  examples, and replay helpers. Rename/move work must be scripted or sliced.
- `TextStreamEventJsonCodec` currently lives in `llm_dart_provider` and encodes
  runtime-like step events. It likely needs to split into provider model-call
  serialization and AI runtime stream serialization.
- Provider replay helpers parse current stream events. They need adapters or
  migration helpers so provider-native replay features are preserved.
- Chat tests use provider event streams heavily. Direct chat migration should
  update test helpers before broad behavior changes.

## Non-Negotiables

- provider packages must not depend on `llm_dart_ai`
- provider packages must not own runtime step lifecycle
- chat must not become the runtime loop owner
- provider-native features and typed provider options stay intact
- replay metadata remains explicit and provider-owned
