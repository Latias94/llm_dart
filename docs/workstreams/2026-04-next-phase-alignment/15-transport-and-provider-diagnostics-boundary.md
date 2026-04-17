# Transport And Provider Diagnostics Boundary

## Goal

Re-check one remaining structural question against the current `repo-ref/ai`
implementation:

> does `llm_dart` still need another shared diagnostics surface for request,
> response, raw chunks, warnings, retries, or provider-native detail?

Or is the current repository already using the more honest layered answer?

## Short Answer

No new shared diagnostics facade should be added now.

The current repository is already close to the correct long-term split:

- common call diagnostics stay in shared result fields and shared stream events
- provider-native detail stays in `ProviderMetadata`
- opt-in raw payload capture stays diagnostic-only
- retry, timeout, per-attempt tracing, and reconnect stay transport-owned
- chat-runtime UI diagnostics stay in `ChatUiMessage.metadata`, reader helpers,
  and transport behavior instead of a new cross-layer observer API

This is already structurally aligned with the useful lesson from
`repo-ref/ai`.

The remaining difference is mostly *shape*, not missing ownership.

## What `repo-ref/ai` Actually Does

The current reference repository does not put all diagnostics into one single
surface.

It spreads them across several layers.

### 1. Shared Result Surface

`GenerateTextResult` and `StreamTextResult` expose shared call diagnostics
through:

- `warnings`
- `request`
- `response`
- `providerMetadata`
- `finishReason` / `rawFinishReason`
- usage and step details

That means the reference repository keeps a stable common subset at the result
layer, while still leaving provider-specific detail under provider-owned
metadata.

### 2. Shared Stream Surface

`stream-text-result.ts` also carries diagnostics in the stream model itself:

- `start-step` includes request plus warnings
- `finish-step` includes response, usage, finish, and provider metadata
- `raw` remains a raw diagnostic event
- many text/reasoning/tool parts can carry `providerMetadata`

Again, this is layered. It is not one giant global diagnostics object.

### 3. UI Stream / Message Processing Layer

`process-ui-message-stream.ts` keeps UI-facing diagnostics in yet another
place:

- merged message metadata
- per-part `providerMetadata`
- tool call/result provider metadata
- finish-state capture in the streamed UI message state

That means the reference repository also distinguishes:

- shared call/result diagnostics
- stream-processing diagnostics
- UI/runtime diagnostics

## What `llm_dart` Already Does Today

The current Dart repository already mirrors the same ownership idea in a
Dart-first shape.

### 1. Shared Result Layer

`GenerateTextResult` already exposes the stable cross-provider subset
directly:

- `warnings`
- `finishReason`
- `rawFinishReason`
- `responseId`
- `responseTimestamp`
- `responseModelId`
- `usage`
- `providerMetadata`

So the repository already has a shared call/result diagnostics layer.

The main difference from `repo-ref/ai` is that `llm_dart` keeps the common
response identity fields flattened instead of wrapping them in one generic
`response` object.

That is a shape choice, not a missing layer.

### 2. Shared Stream Layer

`TextStreamEvent` already carries the same honest common subset:

- `StartEvent.warnings`
- `ResponseMetadataEvent`
- `FinishEvent` usage and provider metadata
- `RawChunkEvent`
- part-level provider metadata on text, reasoning, file, custom, and tool
  events where needed

This already gives direct stream consumers a stable diagnostics channel above
provider codecs and below UI accumulation.

### 3. Shared UI / Message Layer

`ChatUiMessage.metadata` already reserves the shared UI-facing diagnostics
fields:

- `warnings`
- `responseId`
- `responseTimestamp`
- `modelId`
- `responseProviderMetadata`
- `finishReason`
- `rawFinishReason`
- `usage`
- `finishProviderMetadata`
- `errors`
- `rawChunks`

And `ChatUiPart` already preserves provider-native detail where it has direct
UI meaning:

- `TextUiPart.providerMetadata`
- `ReasoningUiPart.providerMetadata`
- `FileUiPart.providerMetadata`
- `ReasoningFileUiPart.providerMetadata`
- `CustomUiPart.providerMetadata`
- `ToolUiPart.callProviderMetadata`
- `ToolUiPart.resultProviderMetadata`

That is already a real UI diagnostics layer, not a missing one.

### 4. Transport Layer

`llm_dart_transport` already keeps transport diagnostics where they belong:

- `TransportDiagnostics`
- `TransportDiagnosticsEvent`
- request start / success / failure events
- per-attempt counters
- timeout information
- retry policy and retry-after handling
- reconnect and replay ownership inside transport/chat transport

This is the correct home for:

- per-attempt request tracing
- retry decisions
- timeout tuning
- HTTP status and header observation
- reconnect checkpoints and replay behavior

Those are transport mechanics, not shared model semantics.

## The Important Comparison Result

The reference repository and `llm_dart` now agree on the important structural
rule:

> diagnostics should be layered by ownership, not collapsed into one public
> observer facade.

The remaining differences are mostly about the exact object shapes.

## Differences That Still Exist

### Difference 1: `repo-ref/ai` Exposes Shared `request` / `response` Objects

The reference repository gives shared result consumers a general-purpose
`request` and `response` object.

`llm_dart` does not currently do that.

Instead it exposes:

- common response identity fields directly
- provider-native detail through `ProviderMetadata`
- transport-native request/response tracing through transport diagnostics

### Decision

Do not add a shared `request` / `response` diagnostics object yet.

Reason:

- many fields in the reference `response` object are transport- or
  provider-shaped rather than stable cross-provider semantics
- the current Dart shared subset is already explicit
- transport already owns the request/attempt/header/status layer honestly

If this ever reopens, the first question should be:

> which exact fields are truly shared enough to deserve a typed common
> request/response object?

not:

> how do we copy the reference repository's object shape literally?

### Difference 2: `repo-ref/ai` Has A Global Warning-Logging Story

The reference repository also routes warnings through a logging helper.

`llm_dart` currently treats warnings primarily as data:

- `GenerateTextResult.warnings`
- `StartEvent.warnings`
- `ChatUiMessage.metadata['warnings']`

### Decision

Keep the Dart approach.

Warnings should stay as explicit result/stream/message data, not become a new
shared global logging facade by default.

Applications and transports can still log them if they want.

### Difference 3: Transport Diagnostics Are More Explicit In Dart

`llm_dart_transport` already has an explicit transport diagnostics interface
for request lifecycle events.

This is more transport-first than the reference repository's public result
surface.

### Decision

Keep transport diagnostics transport-owned.

Do not promote:

- retry attempts
- timeout measurements
- HTTP status/header tracing
- reconnect checkpoints

into `llm_dart_core`, `ChatSession`, or `ChatController`.

## Frozen Ownership Map

The current repository should keep diagnostics ownership as follows.

### Keep In Shared Result / Stream Models

- warnings
- unified finish state
- raw finish reason
- usage
- response ID / timestamp / model ID
- the common provider-metadata escape hatch
- opt-in raw chunk events

### Keep In Shared UI State

- merged call/finish metadata on `ChatUiMessage.metadata`
- part-level provider metadata for renderable text/reasoning/file/custom/tool
  outputs
- reader-level validation and observation helpers

### Keep In Transport

- request lifecycle tracing
- per-attempt diagnostics
- timeout observation
- retry policy
- HTTP status/header response inspection
- reconnect checkpoints and replay bookkeeping

### Keep Provider-Owned

- raw response bodies
- provider-specific request or response payload details
- trace IDs, service tiers, search payloads, logprobs, cache markers, and
  similar provider-native shapes
- compatibility-only or provider-native helper APIs that expose those details
  more directly

## What Should Not Be Added Now

Do not add any of the following in this phase:

- a global shared diagnostics bus in `llm_dart_core`
- `LanguageModel.diagnostics`
- `GenerateTextResult.requestHeaders` or `responseHeaders` as common fields
- `ChatSession.diagnostics`
- `ChatController.diagnostics`
- transport-attempt events promoted into UI/session APIs
- default-on raw chunk capture in shared message metadata

These would mostly mix transport, provider, and UI ownership again.

## Reopen Threshold

This decision should reopen only if repeated real integrations show the same
missing cross-provider diagnostics shape.

Valid signals would look like:

- at least two providers and one shared call path both needing the same typed
  request/response metadata object
- repeated app code reconstructing the same cross-provider trace summary from
  `warnings`, result fields, provider metadata, and transport diagnostics
- a real Flutter or backend integration needing a stable request/response
  diagnostics contract that is not transport-specific and not provider-specific

Absent that evidence, widening the shared diagnostics surface would mostly add
shape symmetry without improving ownership.

## Bottom Line

`llm_dart` is already aligned with the most useful diagnostics lesson from
`repo-ref/ai`:

- shared diagnostics stay shared only where the semantics are real
- provider-native detail stays provider-owned
- transport tracing stays transport-owned
- UI-facing diagnostics stay in message state and reader helpers

The next honest move is not another diagnostics facade.

The next honest move is to keep this layered split frozen until real product
pressure proves that one more shared shape is necessary.
