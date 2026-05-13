# Milestones

## M0: Workstream Opened

Status: complete

Acceptance criteria:

- workstream directory exists
- canonical goal is recorded
- reference and gap audit is recorded
- target runtime surface draft is recorded

## M1: Boundary Decision Freeze

Status: complete

Acceptance criteria:

- final provider model-call event name is chosen: `LanguageModelStreamEvent`
- final AI runtime full-stream event name is chosen: `TextStreamEvent`
- event ownership rules are documented
- public migration story for `TextStreamEvent` is documented
- first implementation slice is selected

Frozen decision:

- provider owns model-call stream events
- AI runtime owns full generation-run events
- providers must not emit runtime step events
- `generateText(...)` and `streamText(...)` become the primary app-facing
  multi-step runtime helpers
- no public `Agent` / `ToolLoopAgent` abstraction in the first code slice
- first code slice introduces provider event vocabulary, runtime adapters, and
  boundary tests before migrating every provider codec

## M2: Provider Model-Call Stream

Status: in progress

Acceptance criteria:

- provider contract exposes only model-call stream parts
- focused providers compile against the new stream contract
- provider serialization tests cover the new vocabulary
- provider packages still do not depend on runtime, chat, Flutter, root, or
  legacy code

Progress:

- 2026-05-13: added `LanguageModelStreamEvent` as the provider-owned stream
  name, provider-side runtime-only event validation, AI runtime adapter seam,
  and focused tests. This is a compatibility first slice; full provider
  signature and codec migration is still pending.
- 2026-05-13: changed `LanguageModel.doStream(...)` to advertise
  `Stream<LanguageModelStreamEvent>` and connected the adapter at
  `streamText(...)` plus `StreamTextRunner` provider-call boundaries. Existing
  focused provider implementations still compile through the compatibility
  typedef.
- 2026-05-13: migrated production focused provider stream implementations,
  stream codecs, provider-native replay/custom helpers, and `llm_dart_test`
  fake model to `LanguageModelStreamEvent` naming while leaving runtime/chat/UI
  surfaces on `TextStreamEvent`.
- 2026-05-13: added `LanguageModelStreamEventJsonCodec` as the provider-owned
  serialization name, kept the existing envelope wire shape for compatibility,
  and added guards so provider serialization and focused provider libs reject
  runtime-only stream semantics.
- 2026-05-13: aligned `llm_dart_core` prompt serialization and runner
  compatibility tests with typed replay options, removing stale prompt-side
  `providerMetadata` expectations from the architecture line.
- 2026-05-13: introduced an AI-owned `TextStreamEventJsonCodec` compatibility
  wrapper and changed `llm_dart_core` serialization exports to resolve the
  runtime full-stream codec through `llm_dart_ai`.
- 2026-05-13: moved app-facing `TextStreamEvent` event-name exports to
  `llm_dart_ai` compatibility aliases and pointed `llm_dart_core` stream event
  exports at the runtime package.
- 2026-05-13: expanded provider boundary guards so provider-facing packages
  cannot runtime-depend on or import root, AI runtime, chat, or Flutter layers;
  also isolated the temporary AI legacy stream codec bridge to one wrapper.
- 2026-05-13: marked `StepStartEvent`, `StepFinishEvent`,
  `ToolOutputDeniedEvent`, and `AbortEvent` as runtime-only in provider
  compatibility code and added focused provider guards against emitting them.
- 2026-05-13: made `LanguageModelStreamEventJsonCodec` own provider
  model-call serialization directly, keeping the existing wire shape while no
  longer delegating through the full runtime stream codec.
- 2026-05-13: narrowed the provider public stream exports so
  `llm_dart_provider` no longer exposes `TextStreamEvent`,
  `TextStreamEventJsonCodec`, or runtime-only full-stream events from its
  public entrypoint.
- 2026-05-13: replaced the provider internal compatibility typedef with a real
  `LanguageModelStreamEvent` sealed class, removed the provider legacy
  full-stream event file and codec, and made provider event classes extend the
  provider model-call base directly.
- 2026-05-13: added a provider metadata boundary guard so ordinary provider
  input contracts cannot accept raw `ProviderMetadata`; replay continues
  through explicit `ProviderReplayPromptPartOptions`.

## M3: Unified Runtime Result Surface

Status: in progress

Acceptance criteria:

- streaming result exposes one consistent set of event, text, output, element,
  step, final result, and UI projection accessors
- non-streaming result and streaming final result share the same step/result
  model
- `GenerateTextRunner` / `StreamTextRunner` duplication is removed or made
  private implementation detail
- structured output stays on `generateTextCall(...)` and `streamTextCall(...)`

Progress:

- 2026-05-13: added consistent `textStream` / `chatUiStream(...)` projection
  accessors across `StreamTextRunResult`, `StreamTextCallResult`, and
  `StreamOutputResult` while preserving existing result types and structured
  output side channels.
- 2026-05-13: expanded `StreamTextRunResult` final-result convenience
  accessors so streaming run callers can inspect content, usage, metadata,
  source, file, and tool data without manually awaiting `result`.
- 2026-05-13: moved concrete full-stream event classes into `llm_dart_ai` and
  added provider/runtime bridge mapping so runtime, UI, chat, and result code
  consume AI-owned `TextStreamEvent` values.
- 2026-05-13: made `TextStreamEventJsonCodec` serialize AI-owned full-stream
  events directly, removing its dependency on the legacy provider full-stream
  codec.
- 2026-05-13: updated the provider/runtime bridge to use
  `LanguageModelStreamEvent` at the provider boundary and reject runtime-only
  AI events when converting back to provider model-call streams.
- 2026-05-13: made `generateText(...)` and `streamText(...)` the primary
  runtime entrypoints by routing them through `GenerateTextRunner` and
  `StreamTextRunner` while preserving `GenerateTextResult` and
  `Stream<TextStreamEvent>` return types.
- 2026-05-13: made `streamText(...)` / `streamTextRun(...)` emit runtime
  `StepStartEvent`, local `ToolResultEvent`, `StepFinishEvent`, and
  `ErrorEvent` semantics around provider model-call events, aligning full
  stream accumulation with step results.
- 2026-05-13: added AI-owned `RunStartEvent` and `RunFinishEvent` full-stream
  lifecycle events so runtime runs are distinct from provider model-call
  `StartEvent` / `FinishEvent` semantics without storing large request or
  prompt payloads in the stream by default.
- 2026-05-13: mapped `CallOptions.cancellation` into runtime `AbortEvent`,
  aborted step finish, and `RunFinishEvent(finishReason: aborted)` semantics so
  user stop is no longer surfaced as a provider/model error in the full stream.
- 2026-05-13: aligned non-streaming `GenerateTextRunner` cancellation with the
  streaming runtime path so `runTextGeneration(...)` returns an aborted run
  result, preserves available partial data, and skips `onError` for user stop.
- 2026-05-13: documented the three stream layers
  (`LanguageModelStreamEvent`, `TextStreamEvent`, and `ChatUiStreamChunk`) in
  package READMEs and workstream migration notes.
- 2026-05-13: introduced an internal stream result foundation that unifies
  replayable event streams, final result completion, error propagation, and
  side-channel lifecycle handling for streaming run, text-call, and
  structured-output result facades while preserving their public API names.
- 2026-05-13: froze `runTextGeneration(...)` and `streamTextRun(...)` as
  advanced runtime result facades for step/run observation, while keeping
  `generateText(...)`, `streamText(...)`, `generateTextCall(...)`, and
  `streamTextCall(...)` as the primary app-facing runtime path.

## M4: Tool Loop Runtime

Status: in progress

Acceptance criteria:

- local tool execution is centralized in `llm_dart_ai`
- tool lifecycle callbacks and result normalization are runtime-owned
- approval, denial, dynamic tool, provider-executed tool, input error, and
  preliminary output semantics are covered by tests
- prompt continuation remains replay-safe

Progress:

- 2026-05-13: added local function tool execution start and finish callbacks
  to the primary and advanced text runtime helpers, implemented centrally in
  `llm_dart_ai`.
- 2026-05-13: normalized local function tool execution into
  `GenerateTextToolExecution` so streaming tool result events, step results,
  and continuation prompt replay use the same runtime-owned execution result.
- 2026-05-13: added composable runtime `stopWhen` conditions
  (`isStepCount`, `isLoopFinished`, `hasToolCall`, and custom predicates) to
  the primary text runtime, advanced runners, and structured-output facades,
  leaving `maxSteps` as the hard safety guard.
- 2026-05-13: deferred dedicated tool-input streaming callbacks because tool
  input chunks are already first-class `TextStreamEvent` values observable via
  `streamText(...)`, `streamTextRun(...)`, and `onChunk`.

## M5: Chat Runtime Integration

Status: in progress

Acceptance criteria:

- `llm_dart_chat` direct transport no longer calls provider streams directly
  for the main runtime path
- chat consumes runtime UI projection or an agent wrapper
- chat state remains transport/persistence/UI focused
- manual tool outputs and approval responses keep ergonomic APIs

Progress:

- 2026-05-13: changed `DirectChatTransport` to call `streamText(...)` and
  project through the AI runtime UI stream path instead of calling
  `LanguageModel.doStream(...)` directly.
- 2026-05-13: extended `ChatRequestOptions` with local runtime tool-loop
  options and made `DirectChatTransport` forward them into `streamText(...)`;
  `HttpChatTransport` now rejects non-serializable local runtime hooks instead
  of silently dropping them.

## M6: Release Readiness

Status: pending

Acceptance criteria:

- migration docs and examples are updated
- boundary guards cover the new ownership rules
- affected package tests pass
- consumer smoke passes
- publish dry-runs pass
