# TODO

## Setup

- [x] Create the workstream scaffold
- [x] Define the canonical goal text
- [x] Record the initial reference and gap audit
- [x] Draft the target runtime surface
- [ ] Link implementation commits as they land

## Decision Freeze

- [ ] Choose final names for provider model-call stream events
- [ ] Choose final names for runtime full-stream events
- [ ] Decide whether old `TextStreamEvent` remains provider-facing during a
  transition or moves fully into `llm_dart_ai`
- [ ] Decide whether single-call provider helpers need explicit public names
  or remain available through `LanguageModel.doGenerate(...)` and
  `LanguageModel.doStream(...)`
- [ ] Freeze whether an `Agent` / `ToolLoopAgent` abstraction is public in this
  line or kept internal behind chat direct transport
- [ ] Freeze `prepareStep`, stop-condition, runtime-context, and tools-context
  scope for the first implementation slice
- [ ] Freeze callback vocabulary for run, step, model call, tool execution,
  chunk, finish, abort, and error events

## Provider Model-Call Boundary

- [ ] Introduce a provider/model-call stream vocabulary that contains only
  model-call parts
- [ ] Remove runtime `StepStartEvent` / `StepFinishEvent` ownership from the
  provider contract or mark them as runtime-only
- [ ] Ensure provider codecs never need to emit chat/UI lifecycle chunks
- [ ] Add serialization guards for provider model-call stream parts
- [ ] Update focused providers to emit the new model-call stream parts
- [ ] Keep provider metadata response-side and replay-only

## AI Runtime Full Stream

- [ ] Create one full-stream event vocabulary in `llm_dart_ai`
- [ ] Emit explicit run start, step start, provider/model-call parts, tool
  execution parts, step finish, run finish, abort, and error events
- [ ] Ensure stream accumulation uses the full-stream event semantics
- [ ] Ensure result accumulation is step-scoped and final-run scoped
- [ ] Add step request/response metadata inclusion policy to avoid storing
  large payloads by default
- [ ] Add guards so runtime step events cannot be emitted by provider packages

## Result Surface Consolidation

- [ ] Make `generateText(...)` the app-facing non-streaming multi-step helper
- [ ] Make `streamText(...)` the app-facing streaming multi-step helper
- [ ] Keep `generateTextCall(...)` and `streamTextCall(...)` as the structured
  text/result facades
- [ ] Replace duplicate `StreamTextRunResult`, `StreamTextCallResult`, and
  `StreamOutputResult` plumbing with one consistent result foundation
- [ ] Preserve `partialOutputStream` and `elementStream`
- [ ] Add `textStream` and UI projection accessors to the streaming result
- [ ] Decide migration path for `runTextGeneration(...)` and `streamTextRun(...)`

## Tool Loop

- [ ] Centralize local function tool execution in `llm_dart_ai`
- [ ] Add tool execution start/end callbacks
- [ ] Add tool input streaming callbacks or document why they are deferred
- [ ] Add tool context and runtime context if they fit Dart ergonomics
- [ ] Add stop conditions beyond `maxSteps`
- [ ] Add approval request/response continuation semantics
- [ ] Add dynamic tool and tool input error semantics
- [ ] Preserve provider-executed tools and deferred provider results
- [ ] Preserve replay-safe provider options on prompt continuations

## Chat Boundary

- [ ] Make direct chat transport consume the AI runtime or an agent wrapper
- [ ] Remove duplicate provider stream accumulation from chat where runtime can
  own it
- [ ] Keep chat responsible for chat state, persistence, transport, and manual
  tool output submission
- [ ] Keep UI stream protocol stable or provide migration notes if chunk names
  change
- [ ] Ensure chat automatic tool execution delegates to the runtime tool
  execution model or has a documented adapter boundary

## Documentation And Migration

- [ ] Update `llm_dart_ai` README with the frozen runtime surface
- [ ] Update `llm_dart_chat` README with the new direct transport story
- [ ] Update examples to use the primary runtime helpers
- [ ] Add migration notes for old stream events and runner helpers
- [ ] Add architecture docs that explain provider model-call stream versus AI
  runtime full stream

## Validation

- [ ] Run workspace dependency guards
- [ ] Run provider boundary guards
- [ ] Run root package boundary guards
- [ ] Run focused provider tests affected by event changes
- [ ] Run `llm_dart_provider` stream serialization tests
- [ ] Run `llm_dart_ai` runtime, output, prompt, and UI projection tests
- [ ] Run `llm_dart_chat` direct transport and tool execution tests
- [ ] Run examples analysis
- [ ] Run consumer smoke
- [ ] Run publish dry-runs
- [ ] Run `git diff --check`
