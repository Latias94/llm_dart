# Repo-Ref Structure Gap Review

## Goal

This note answers the next comparison question after the shared runner,
provider-owned replay contracts, and Google mixed-tool slice landed:

> Which parts of `llm_dart` are already structurally aligned with `repo-ref/ai`,
> which differences are deliberate, and which structural gaps are still real?

The important point is discipline:

- not every difference is a defect
- some differences are Dart-first design choices
- only a small subset of the remaining differences should drive the next
  breaking-round refactor

## 1. Reference Signals From `repo-ref/ai`

The reference repository is useful because it is mature in four specific ways.

### 1. Provider Abstraction

Its architecture is clearly split into:

- AI functions
- model specifications
- provider implementations

That separation prevents providers from leaking protocol details into the main
API.

### 2. Layered Messages

It distinguishes:

- UI messages
- model messages
- language-model-spec messages
- provider-specific messages

That layered message model keeps rendering, request replay, and provider wire
encoding from collapsing into one bus structure.

### 3. Streamed Multi-Step Orchestration

Its text pipeline is more than a raw provider stream. It also owns:

- step preparation
- tool execution transforms
- stitched multi-step streaming
- step lifecycle hooks
- finish/start step markers above the provider stream

### 4. Capability Modules

Its main package already has first-class modules for:

- `generate-text`
- `generate-object`
- `embed`
- `generate-image`
- `generate-speech`
- `transcribe`
- `ui-message-stream`
- `middleware`
- `registry`
- `telemetry`

That does not mean we should copy every module directly, but it does show where
their architecture has already become productized rather than implicit.

## 2. Areas Where `llm_dart` Is Already Structurally Aligned

Several of the biggest historical architecture problems are no longer the main
gap.

### 2.1 Shared Spec Versus Provider Packages

`llm_dart` now already follows the important split:

- shared spec and models in `llm_dart_core`
- shared HTTP and streaming mechanics in `llm_dart_transport`
- provider implementations in provider-owned packages

This is the same architectural direction as the reference, even though our
package count is intentionally smaller.

### 2.2 Layered Message Families

We now already have separate layers for:

- prompt replay
- generated content and stream events
- UI-facing chat messages
- provider-owned custom parts and provider metadata

This is the right Dart equivalent of the reference message-layer rule.

### 2.3 Provider-Native Features Stay Provider-Owned

The refactor has already moved in the correct direction for:

- provider-native tool declaration
- provider-native replay payloads
- provider-specific file handles and execution payloads
- provider-specific search controls
- provider-specific selection or forcing rules

This is especially visible in the Anthropic execution path and the Google
mixed-tool replay path.

### 2.4 Flutter Is Separated From Core Provider Logic

`llm_dart_flutter` now owns:

- session orchestration
- transport integration
- persistence and snapshots
- UI message projection

This is structurally better than the old monolith and already mirrors the
reference lesson that UI/session concerns should not leak into the provider
codec layer.

### 2.5 Step Lifecycle Has Started To Exist Above The Raw Stream

The reference still has a richer orchestration loop, but we are no longer at
zero:

- `GenerateTextStepResult`
- `GenerateTextRunResult`
- `GenerateTextStepStartEvent`
- `GenerateTextRunner`

That means the architecture is already aligned on the important principle:
step lifecycle belongs above the raw provider stream, not inside it.

## 3. Differences That Are Deliberate And Should Stay Deliberate

Some structural differences from `repo-ref/ai` are healthy and should not be
treated as missing work.

### 3.1 No Package Explosion

We should not copy:

- one package per provider family variation
- a public `provider-utils` package
- multiple UI framework packages
- a large adapter ecosystem before the core stabilizes

The current medium-grained workspace is a better fit for a Dart-first and
Flutter-focused repository.

### 3.2 No Shared UI Chunk Exhaustiveness In Core

We should not copy the full `ui-message-stream` vocabulary into
`TextStreamEvent`.

The shared core should continue to model provider-stream semantics, while
transport or session protocols may add richer UI chunk markers separately.

### 3.3 No Heavy Agent Runtime In Phase 1

The reference repository includes modules such as `agent`, `middleware`, and
`telemetry`.

Those are useful reference signals, but they are not the next required
foundation for `llm_dart`. If we add them too early, we risk creating new
surface area before the core capability modules are fully stable.

## 4. Real Structural Gaps Still Remaining

After the recent refactor rounds, the remaining differences that still matter
cluster into four structural gaps.

### 4.1 No Shared Structured-Generation Module Yet

This is now the clearest gap versus the reference capability layout.

Current status:

- shared structured output now exists in `llm_dart_core` through
  `OutputSpec`, `generateOutput(...)`, `streamOutput(...)`, and
  `streamOutputResult(...)`
- the additive main-call layer now also exists through `generateTextCall(...)`
  and `streamTextCall(...)`
- OpenAI and Google already have provider-owned JSON-schema request support
- the shared helper already covers built-in `text`, `json`, `object`,
  `array`, and `choice` modes for final-output parsing
- streamed text can now reuse the same shared `OutputSpec` contract, emit
  best-effort partial structured-output events during the raw
  `TextStreamEvent` sequence, emit shared array `OutputElementEvent`s for newly
  completed elements, and emit one final parsed-output event at the end
- the higher-level streamed structured-output surface now also exposes buffered
  `partialOutputStream`, `elementStream<T>()`, final `output`, and typed
  `result` access without redefining `streamText(...)`

What is still missing:

- tighter integration between structured output and the main shared text call
  surface
- a clearer long-term result-placement strategy if parsed output should later
  live directly beside `GenerateTextResult`
- a decision on whether the additive `generateTextCall(...)` /
  `streamTextCall(...)` layer should later fold into `generateText(...)` /
  `streamText(...)` directly instead of staying explicit

Why this matters:

- it is the main remaining gap between “provider features exist” and “the
  capability is productized as a common API”
- Flutter apps and server-side apps both benefit from one stable structured
  generation surface instead of provider-specific `responseFormat` branches

Recommended rule:

- do not add this blindly
- first prove that at least OpenAI and Google can share a truthful contract
  without hiding meaningful provider differences

### 4.2 The Shared Runner Is Still Much Narrower Than The Reference Stream Loop

Current status:

- we have a non-streaming shared `GenerateTextRunner`
- it only supports app-executed common function tools
- it intentionally does not own provider-native continuation, approval-heavy
  continuation, or dynamic tools

What is still missing compared with the reference:

- streamed multi-step orchestration
- stitchable multi-step run streams
- pre-step mutation hooks such as `prepareStep`
- stronger stop-policy layers above `maxSteps`
- richer run lifecycle hooks for streamed flows

This is a real maturity gap, but it should stay tightly scoped.

The wrong move would be:

- widening shared request models for provider-native continuation
- pushing approval or provider-executed tool semantics into the core runner
- redefining `streamText(...)` itself as a multi-step runtime

### 4.3 Capability Helper Surfaces Have Landed, But Provider Parity Is Still Incomplete

The common interfaces already exist for:

- embeddings
- images
- speech
- transcription

The shared capability-helper surface is no longer missing.

Current status:

- `llm_dart_core` now exposes top-level `embed(...)`, `embedMany(...)`,
  `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`
- those helpers now provide the intended app-facing function-based entrypoints
  above the raw model interfaces
- the first non-text provider migration has also landed for the OpenAI family
  through `OpenAI.embeddingModel(...)`

What is still missing:

- provider migrations for image, speech, and transcription are still
  incomplete
- Google and Anthropic non-text capability migrations are still incomplete
- shared embedding chunk-splitting and parallel-batching policy is not yet
  frozen above the raw model interface

This means the architecture now has the correct shared product surface, but it
is still not as complete as the reference package layout on provider migration
coverage and mature capability internals.

### 4.4 The Remote UI Stream Protocol Is Still Intentionally Thin

`llm_dart_flutter` already has:

- `HttpChatTransport`
- prompt and UI codecs
- session snapshots
- serialized `TextStreamEvent` transport chunks

What it does not yet have is a richer remote UI stream vocabulary comparable to
the reference `ui-message-stream` layer, such as:

- message start markers
- finish markers separated from provider finish events
- metadata patches
- abort markers
- other remote-only session markers

This is not automatically a defect, but it remains a structural difference that
may matter if we want richer backend-driven chat UX, resumability, or
cross-process orchestration later.

## 5. Recommended Refactor Order From Here

The next refactor sequence should focus on the real gaps, not on package-count
parity.

### 5.1 Decide The Shared Structured-Generation Boundary

This is the highest-value architecture question now that text generation,
provider-native replay, and Flutter session boundaries are largely stabilized.

The first question is not implementation detail. It is scope honesty:

- can we define a truthful `generateObject` / `streamObject` boundary
- or should structured generation stay provider-owned longer

### 5.2 Re-Evaluate Whether A Streamed Runner Is Worth Adding

Only revisit this after at least one concrete shared call path proves the
need.

If added later, it should be:

- a separate higher-level orchestration layer above `streamText(...)`
- still limited to genuinely shared continuation semantics

### 5.3 Finish Non-Text Provider Migration Parity

Once the structured-generation direction is clear, finish the remaining
provider-migration work in a consistent way:

- image model migration
- speech model migration
- transcription model migration
- Google and Anthropic capability migration parity
- only then re-evaluate whether embeddings need shared chunk splitting above
  `EmbeddingModel.embed(...)`

### 5.4 Defer Optional Cross-Cutting Modules

Only revisit modules such as:

- middleware
- registry expansion
- telemetry
- agent runtime

after the capability modules and transport foundations are stable.

## Conclusion

After the current architecture refactor rounds, `llm_dart` is already aligned
with `repo-ref/ai` on the most important structural rules:

- shared spec versus provider implementation
- layered message families
- provider-owned native features
- Flutter/session separation
- step lifecycle living above the raw stream
- transport-owned retry, timeout, diagnostics, and streaming helpers

The remaining structural gaps are now narrower and clearer:

- shared structured generation
- streamed runner maturity
- non-text provider migration parity and possible future embedding batching
  policy
- possibly richer remote UI streaming later

That is a much safer place to continue refactoring from than the old
“everything is coupled” starting point.
