# Core Contract Audit

Audit date: 2026-05-18.

This document is the decision log for the `llm_dart_provider` contract seam.
It compares the current Dart provider contracts with `repo-ref/ai` provider v4
contracts and records what to keep, change, or defer. It does not change public
API by itself.

## Decision Labels

- Keep: the current Dart contract has the right seam and should remain.
- Change: the next breaking line should alter the provider-facing contract.
- Defer: the reference has a useful idea, but the Dart library should wait
  until runtime, provider parity, or migration evidence proves the seam.

## Reference Lessons

The reference provider v4 shape is useful because it keeps provider
implementation contracts separate from runtime orchestration:

- model calls receive provider-facing call options, not user prompts
- results separate generated content, finish reason, usage, warnings, provider
  metadata, request diagnostics, and response diagnostics
- streaming emits provider-owned output parts, not runtime lifecycle events
- provider options are input-side controls
- provider metadata is output-side observation and replay data
- provider objects own model lookup by kind
- numeric batching limits are direct model facts when the runtime must schedule
  around them

The Dart target should preserve Dart-specific strengths:

- typed provider model, invocation, and prompt-part options
- a unified `UsageStats` summary for cross-model runtime aggregation
- capability profiles for app-facing feature discovery
- provider-native helper clients for features that are not yet stable shared
  seams
- a single provider package contract instead of TypeScript version-folder
  unions

## Cross-Cutting Decisions

### Provider Call Envelope

Decision: Keep.

Current Dart requests (`GenerateTextRequest`, `EmbedRequest`,
`ImageGenerationRequest`, `SpeechGenerationRequest`, and
`TranscriptionRequest`) already act as provider-facing call envelopes. They
combine normalized prompt/input data with `CallOptions`, which owns headers,
timeouts, retry policy, cancellation, and typed `ProviderInvocationOptions`.

Do not add a separate request metadata object before provider calls. The
reference does not use input request metadata for provider customization; it
uses provider options. Request telemetry belongs in diagnostics or provider
metadata only after a redaction policy exists.

### Provider Options And Provider Metadata

Decision: Keep.

`ProviderInvocationOptions` is the Dart equivalent of reference
`providerOptions`, but safer because concrete providers can expose typed option
objects instead of weak JSON records. `ProviderMetadata` already preserves the
reference's output-side namespace rule and keeps replay metadata out of
input-authored prompt parts.

Do not flatten provider-specific features into shared options unless at least
two providers prove a durable shared seam.

### Response Metadata

Decision: Change.

Language results still expose `responseId`, `responseTimestamp`, and
`responseModelId` as separate fields, while embedding, image, speech, and
transcription use `ModelResponseMetadata`. The next breaking line should make
the provider-facing contract consistent:

- add optional `id` to `ModelResponseMetadata`
- allow `timestamp` and `modelId` to be optional where providers do not report
  them
- keep `headers` on the response metadata wrapper
- replace language result response fields with `responseMetadata`
- make `ResponseMetadataEvent` carry the same wrapper

Runtime and facade packages may keep derived aliases during migration, but the
provider contract should have one response metadata shape.

Defer raw request/response body fields. The reference exposes body diagnostics,
but adding them directly to public provider results risks leaking sensitive
payloads and increasing memory use. Revisit after transport diagnostics and
redaction rules are audited.

### Usage

Decision: Keep, with targeted expansion.

The reference uses model-kind-specific usage types. Dart should keep
`UsageStats` as the unified summary because it gives the runtime one aggregation
surface across language, embedding, image, speech, and transcription. That is a
deliberate Dart library feature.

The next breaking line should not replace `UsageStats` with separate usage
classes. Instead, expand it only where the value is cross-provider and
runtime-useful:

- cache read/write input token counts for language models
- text versus reasoning output token counts if more providers expose them
- raw provider usage only after a redaction and serialization policy exists

Provider-specific counters remain in `ProviderMetadata`.

### Warnings

Decision: Change.

Reference warnings distinguish unsupported, compatibility, deprecated, and
other warnings, and they name a feature or setting. Dart currently has
unsupported, compatibility, and other warnings with `message` and `field`.

The next breaking line should:

- add `ModelWarningType.deprecated`
- add a stable `feature` or `setting` field instead of overloading `field`
- keep `message` for human-readable context
- preserve provider-owned details through `ProviderMetadata` when needed

### Capability Profiles And Direct Limits

Decision: Change.

Capability profiles are good for app-facing discovery, but some provider facts
are scheduling constraints rather than descriptive capabilities. The reference
puts `maxEmbeddingsPerCall`, `supportsParallelCalls`, and `maxImagesPerCall`
directly on model contracts.

The next breaking line should move these facts into shared model interfaces:

- `EmbeddingModel.maxEmbeddingsPerCall`
- `EmbeddingModel.supportsParallelCalls`
- `ImageModel.maxImagesPerCall`

Provider packages already expose some of these values ad hoc. Making them part
of the interface improves locality: batching, validation, and runtime
scheduling no longer need provider-specific knowledge or capability-profile
detail parsing.

Keep capability profiles for feature discovery and provider-specific detail.

### Provider Object And Registry

Decision: Keep `ProviderRegistry`, change `ModelRegistry` posture.

`ProviderRegistry` matches the reference provider-object seam: one provider
object exposes language, embedding, image, speech, and transcription model
facets. Keep it as the modern lookup path.

`ModelRegistry` is a factory-map compatibility adapter. It should not shape new
provider architecture. The breaking-line posture is:

- keep it only as a migration adapter if consumers still depend on it
- mark it as legacy/deprecated when the public migration line starts
- remove it from modern facade exports when compatibility exits

Do not add a `specificationVersion` field now. TypeScript needs discriminated
provider interface versions; this Dart package can rely on semver until there
is real evidence that multiple provider-contract versions must coexist.

## Model-Kind Audit

### Language Model

Reference files:

- `repo-ref/ai/packages/provider/src/language-model/v4/language-model-v4.ts`
- `repo-ref/ai/packages/provider/src/language-model/v4/language-model-v4-call-options.ts`
- `repo-ref/ai/packages/provider/src/language-model/v4/language-model-v4-generate-result.ts`
- `repo-ref/ai/packages/provider/src/language-model/v4/language-model-v4-stream-part.ts`

Decisions:

- Keep provider-facing `GenerateTextRequest`. It is not a user prompt; it is
  the normalized prompt and call envelope.
- Keep `doGenerate` and `doStream` naming. This correctly discourages direct
  app-facing usage.
- Keep provider-owned stream events. Current events already exclude runtime
  lifecycle events such as step start, step finish, approval handling, and
  abort.
- Keep content parts for text, reasoning, tool calls, tool results, approval
  requests, sources, files, custom content, and raw chunks.
- Change response metadata to use `ModelResponseMetadata` instead of language
  result scalar fields.
- Change warning shape as described above.
- Keep typed provider invocation options in `CallOptions`.
- Change `ReasoningEffort` to cover the reference-level vocabulary where it is
  useful: `provider-default` is represented by null, `none` is represented by
  disabled reasoning, and `xhigh` should be added if providers expose it.
  Preserve Dart's `budgetTokens` extension as provider-friendly structure.
- Defer `supportedUrls` until the transport/runtime audit decides whether URL
  prompt parts should be downloaded, passed through, or provider-referenced.

Migration notes:

- Provider result codecs will construct `ModelResponseMetadata`.
- `llm_dart_ai` can keep `responseId` aliases on user-facing result facades
  while reading the provider wrapper underneath.
- Stream bridge code should map one provider `ResponseMetadataEvent` to runtime
  response metadata events.

### Embedding Model

Reference files:

- `repo-ref/ai/packages/provider/src/embedding-model/v4/embedding-model-v4.ts`
- `repo-ref/ai/packages/provider/src/embedding-model/v4/embedding-model-v4-call-options.ts`
- `repo-ref/ai/packages/provider/src/embedding-model/v4/embedding-model-v4-result.ts`

Decisions:

- Keep `EmbedRequest.values` as the provider-facing batch input.
- Keep `dimensions` on the request. It is a shared option with real provider
  support, and unsupported dimensions can be reported through warnings.
- Change `EmbeddingModel` to expose `maxEmbeddingsPerCall` and
  `supportsParallelCalls` directly.
- Keep `UsageStats` for embedding token summaries. Embeddings naturally map to
  `inputTokens` and `totalTokens`.
- Keep response metadata and provider metadata.
- Change warnings to the normalized warning shape.

Migration notes:

- OpenAI already has `maxEmbeddingsPerCall`; promote it to the interface.
- Google should expose the reference-aligned 2048 embedding batch limit.
- Ollama should return `null` for no published hard batch limit and keep
  parallel scheduling conservative until runtime batching has provider evidence.
- Runtime batching should use the direct interface facts instead of parsing
  capability-profile provider details.

### Image Model

Reference files:

- `repo-ref/ai/packages/provider/src/image-model/v4/image-model-v4.ts`
- `repo-ref/ai/packages/provider/src/image-model/v4/image-model-v4-call-options.ts`
- `repo-ref/ai/packages/provider/src/image-model/v4/image-model-v4-result.ts`
- `repo-ref/ai/packages/provider/src/image-model/v4/image-model-v4-usage.ts`

Decisions:

- Keep `GeneratedImage` instead of returning only raw base64 or bytes. Dart
  callers benefit from a structured image object with bytes, URI, and media
  type.
- Change `ImageModel` to expose `maxImagesPerCall` directly.
- Change `ImageGenerationRequest` to support the common image operation seam:
  optional prompt, count, size, aspect ratio, seed, input files, and mask.
- Change `GeneratedImage` to support per-image provider metadata. Global
  `providerMetadata` remains useful for call-level data.
- Keep provider-native edit and variation helper methods as convenience
  surfaces, but do not require separate shared model methods. The common seam
  should be one request shape with files/mask; providers can warn when a model
  does not support it.
- Keep `UsageStats` for image token summaries.
- Change warnings to the normalized warning shape.

Migration notes:

- OpenAI and Google already have native edit/variation paths. They are the
  first providers to prove the common files/mask request seam.
- Existing `doGenerate` call sites can migrate mechanically from `prompt`,
  `count`, and `size` to the expanded request object.
- Implemented common `ImageGenerationRequest.files` and `mask` support through
  OpenAI edits and Google Gemini image editing while retaining provider-owned
  `edit` and variation helpers.
- `GeneratedImage.providerMetadata` now carries per-image provider metadata;
  call-level `ImageGenerationResult.providerMetadata` remains the aggregated
  compatibility surface.
- Provider-specific image options such as style, quality, safety policy, or
  output format remain typed provider invocation options.

### Speech Model

Reference files:

- `repo-ref/ai/packages/provider/src/speech-model/v4/speech-model-v4.ts`
- `repo-ref/ai/packages/provider/src/speech-model/v4/speech-model-v4-call-options.ts`
- `repo-ref/ai/packages/provider/src/speech-model/v4/speech-model-v4-result.ts`

Decisions:

- Keep `SpeechGenerationRequest.text` and `voice`.
- Change `SpeechGenerationRequest` to include shared fields for output format,
  instructions, speed, and language when at least OpenAI, Google, or
  ElevenLabs can map them.
- Keep typed provider invocation options for provider-specific voice settings,
  stability, similarity, pronunciation dictionaries, or model-specific flags.
- Keep `audioBytes` plus `mediaType`; that is the Dart-friendly version of the
  reference's string-or-bytes audio result.
- Change result response metadata to the common wrapper.
- Change warnings to the normalized warning shape.
- Defer raw request/response body diagnostics.

Migration notes:

- OpenAI, Google, and ElevenLabs speech request builders should all resolve the
  shared fields first, then apply typed provider option precedence.
- Result codecs should populate media type explicitly instead of relying on
  caller-side fallback rules.

### Transcription Model

Reference files:

- `repo-ref/ai/packages/provider/src/transcription-model/v4/transcription-model-v4.ts`
- `repo-ref/ai/packages/provider/src/transcription-model/v4/transcription-model-v4-call-options.ts`
- `repo-ref/ai/packages/provider/src/transcription-model/v4/transcription-model-v4-result.ts`

Decisions:

- Keep text, segments, language, and duration. This already matches the
  reference's stable transcription output seam.
- Change provider-facing requests to require a media type. Public facade
  helpers may infer one, but providers should not receive ambiguous audio
  bytes.
- Keep typed provider invocation options for timestamp granularity, diarization,
  language hints, prompt hints, and model-specific features.
- Change result response metadata to the common wrapper.
- Change warnings to the normalized warning shape.
- Defer word-level timestamps as a shared core field. Keep them in
  provider-specific metadata until multiple providers expose a compatible
  representation.

Migration notes:

- OpenAI and ElevenLabs transcription adapters should be the first migration
  targets because both already return response metadata and support
  provider-specific transcription options.

## First Implementation Slices

Do these in order. Each slice should be small enough to test independently.

1. Response metadata normalization - implemented
   - extend `ModelResponseMetadata`
   - migrate language result and stream metadata to the wrapper
   - keep runtime aliases during migration
   - update provider result/stream codecs and serialization tests
2. Direct model limits - implemented
   - add embedding and image limit getters to shared interfaces
   - update OpenAI, Google, Ollama, and test providers
   - keep runtime batching changes deferred until result facades can represent
     multiple response metadata records without data loss
3. Image common request seam
   - expand `ImageGenerationRequest`
   - add per-image provider metadata
   - adapt OpenAI and Google edit/variation paths behind the common request
4. Speech and transcription request completion
   - add shared speech request fields
   - require provider-facing transcription media type
   - settle provider option precedence tests
5. Warning normalization
   - add deprecated warning support
   - migrate provider request-policy warnings
   - update JSON serialization compatibility rules

## Validation Plan

For each implementation slice:

- run focused provider contract tests in `packages/llm_dart_provider`
- run touched provider package tests
- run `llm_dart_ai` result and stream bridge tests when language metadata or
  usage changes
- run serialization tests for warnings, usage, stream events, and prompt
  replay metadata
- run package analysis for touched packages
- run `git diff --check`

The full workstream release gate remains in `MILESTONES.md` M6.

## First Slice Non-Goals

Do not do these during the first core-contract implementation slice:

- publish a public `llm_dart_provider_utils` package
- copy TypeScript provider v4 version folders literally
- replace typed provider options with JSON maps
- remove provider-native helper clients
- expose raw request/response bodies without redaction policy
- make `llm_dart_core` own new architecture
