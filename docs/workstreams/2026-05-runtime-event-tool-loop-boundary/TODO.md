# TODO

## Setup

- [x] Create the workstream scaffold
- [x] Define the canonical goal text
- [x] Record the initial reference and gap audit
- [x] Draft the target runtime surface
- [x] Link first implementation slice as it landed
- [x] Link later implementation commits as they land

## Decision Freeze

- [x] Choose final names for provider model-call stream events
- [x] Choose final names for runtime full-stream events
- [x] Decide whether old `TextStreamEvent` remains provider-facing during a
  transition or moves fully into `llm_dart_ai`
- [x] Decide whether single-call provider helpers need explicit public names
  or remain available through `LanguageModel.doGenerate(...)` and
  `LanguageModel.doStream(...)`
- [x] Freeze whether an `Agent` / `ToolLoopAgent` abstraction is public in this
  line or kept internal behind chat direct transport
- [x] Freeze `prepareStep`, stop-condition, runtime-context, and tools-context
  scope for the first implementation slice
- [x] Freeze callback vocabulary for run, step, model call, tool execution,
  chunk, finish, abort, and error events

Decision notes:

- provider model-call stream base name is `LanguageModelStreamEvent`
- runtime full-stream base name is `TextStreamEvent`
- `TextStreamEvent` moves to `llm_dart_ai` ownership and must not remain
  provider-facing after the migration window
- `generateText(...)` and `streamText(...)` become app-facing runtime helpers
- provider single-call behavior remains available through
  `LanguageModel.doGenerate(...)` and `LanguageModel.doStream(...)`
- no public `Agent` / `ToolLoopAgent` abstraction in the first code slice
- keep `maxSteps` as the hard safety guard; use composable `stopWhen`
  conditions for runtime loop policy
- first implementation slice introduces provider event vocabulary, runtime
  adapters, and provider boundary tests before migrating every provider codec

## Provider Model-Call Boundary

- [x] Introduce a provider/model-call stream vocabulary that contains only
  model-call parts
- [x] Add provider-side guards/tests that reject runtime-only events
- [x] Add an AI-runtime adapter seam for provider model-call streams
- [x] Migrate focused provider production code to the
  `LanguageModelStreamEvent` name
- [x] Remove runtime `StepStartEvent` / `StepFinishEvent` ownership from the
  provider contract or mark them as runtime-only
- [x] Remove provider public exports for `TextStreamEvent`,
  `TextStreamEventJsonCodec`, and runtime-only full-stream events
- [x] Remove provider internal legacy `TextStreamEvent` ownership and make
  `LanguageModelStreamEvent` the real provider model-call base
- [x] Ensure provider codecs never need to emit chat/UI lifecycle chunks
- [x] Add serialization guards for provider model-call stream parts
- [x] Update focused providers to emit the new model-call stream parts
- [x] Keep provider metadata response-side and replay-only

## AI Runtime Full Stream

- [x] Create one full-stream event serialization owner in `llm_dart_ai`
- [x] Create one full-stream event export owner in `llm_dart_ai`
- [x] Create one full-stream event vocabulary in `llm_dart_ai`
- [x] Emit explicit run start, step start, provider/model-call parts, tool
  execution parts, step finish, run finish, abort, and error events
- [x] Emit runtime step start, provider/model-call parts, local tool result
  parts, step finish, and error events from `streamText(...)`
- [x] Emit runtime run start and run finish events from `streamText(...)`
- [x] Map runtime cancellation to abort events and aborted run finish
- [x] Align non-streaming runtime cancellation with streaming abort semantics
- [x] Ensure stream accumulation uses the full-stream event semantics
- [x] Ensure result accumulation is step-scoped and final-run scoped
- [x] Add step request/response metadata inclusion policy to avoid storing
  large payloads by default
- [x] Add guards so runtime step events cannot be emitted by provider packages

## Result Surface Consolidation

- [x] Make `generateText(...)` the app-facing non-streaming multi-step helper
- [x] Make `streamText(...)` the app-facing streaming multi-step helper
- [x] Keep `generateTextCall(...)` and `streamTextCall(...)` as the structured
  text/result facades
- [x] Replace duplicate `StreamTextRunResult`, `StreamTextCallResult`, and
  `StreamOutputResult` plumbing with one consistent result foundation
- [x] Preserve `partialOutputStream` and `elementStream`
- [x] Add `textStream` and UI projection accessors to the streaming result
- [x] Decide migration path for `runTextGeneration(...)` and `streamTextRun(...)`

## Tool Loop

- [x] Centralize local function tool execution in `llm_dart_ai`
- [x] Add tool execution start/end callbacks
- [x] Add tool input streaming callbacks or document why they are deferred
- [x] Add tool context and runtime context if they fit Dart ergonomics
- [x] Add stop conditions beyond `maxSteps`
- [x] Add approval request/response continuation semantics
- [x] Add dynamic tool semantics
- [x] Add tool input error semantics
- [x] Preserve provider-executed tools and deferred provider results
- [x] Preserve replay-safe provider options on prompt continuations

## Chat Boundary

- [x] Make direct chat transport consume the AI runtime or an agent wrapper
- [x] Remove duplicate provider stream accumulation from chat where runtime can
  own it
- [x] Keep chat responsible for chat state, persistence, transport, and manual
  tool output submission
- [x] Keep UI stream protocol stable or provide migration notes if chunk names
  change
- [x] Ensure chat automatic tool execution delegates to the runtime tool
  execution model or has a documented adapter boundary

## Documentation And Migration

- [x] Update `llm_dart_ai` README with the frozen runtime surface
- [x] Update `llm_dart_chat` README with the new direct transport story
- [x] Update examples to use the primary runtime helpers
- [x] Add migration notes for old stream events and runner helpers
- [x] Add architecture docs that explain provider model-call stream versus AI
  runtime full stream

## Validation

- [x] Run workspace dependency guards
- [x] Run provider boundary guards
- [x] Run root package boundary guards
- [x] Run focused provider tests affected by event changes
- [x] Run `llm_dart_provider` stream serialization tests
- [x] Run `llm_dart_core` prompt replay and runner compatibility tests
- [x] Run `llm_dart_ai` stream serialization ownership tests
- [x] Run `llm_dart_ai` stream event export ownership tests
- [x] Run `llm_dart_ai` runtime, output, prompt, and UI projection tests
- [x] Run `llm_dart_chat` direct transport and tool execution tests
- [x] Run examples analysis
- [x] Run consumer smoke
- [x] Run publish dry-runs
- [x] Run `git diff --check`
