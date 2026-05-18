# Provider Parity Matrix

## Purpose

This matrix tracks alignment by provider and feature. It should guide future
implementation slices after the core contract audit. The goal is not perfect
feature symmetry. The goal is clear ownership: shared features become shared
contracts, provider-native features stay provider-owned, and unsupported
features fail or warn predictably.

## Legend

- `Done` - implemented and covered by focused tests
- `Partial` - implemented with known gaps or limited tests
- `Provider-owned` - intentionally not promoted to shared contract
- `Defer` - not implemented and not part of the current breaking line
- `Audit` - needs source comparison before decision

## Matrix

| Provider | Language | Embedding | Image | Speech | Transcription | Stream | Metadata | Capability Profile | Native Helpers |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OpenAI | Done | Done | Done | Done | Done | Done | Done | Done | Files, moderation, responses lifecycle, assistants remain provider-owned |
| Google | Done | Done | Done | Done | Defer | Done | Done | Done | Imagen/Gemini image editing and Google-specific options remain provider-owned |
| Anthropic | Done | Defer | Defer | Defer | Defer | Done | Done | Done | Count tokens and Anthropic beta/tool policy remain provider-owned |
| Ollama | Done | Done | Defer | Defer | Defer | Done | Done | Done | Local catalog and binary resolver behavior remain provider-owned |
| ElevenLabs | Defer | Defer | Defer | Done | Done | Defer | Done | Done | Voice catalog remains provider-owned |
| OpenAI-compatible family | Done | Audit | Audit | Audit | Audit | Done | Audit | Done | Family profiles and option policies remain provider-owned over shared wire code |

## Shared Option Coverage

Current shared language options:

- `maxOutputTokens`
- `temperature`
- `stopSequences`
- `topP`
- `topK`
- `presencePenalty`
- `frequencyPenalty`
- `seed`
- `reasoning`
- `includeRawChunks`
- `responseFormat`

Audit per provider:

- supported natively
- ignored with warning
- coerced to provider-specific equivalent
- rejected because provider option conflicts
- unsupported and undocumented

## Provider-Native Option Coverage

Each provider row should record:

- model settings
- invocation options
- prompt-part options
- raw escape hatches, if any
- conflict rules with shared options
- profile-specific rejection behavior

## Metadata Coverage

Each provider row should record:

- namespace key
- response ids
- model ids and timestamps
- usage/token counters
- finish reasons
- stream-specific metadata
- replay metadata
- raw response details retained for observability

## Capability Profile Coverage

Each provider row should record:

- supported model kinds
- streaming support
- tool support
- structured output support
- image count/size/edit support
- speech/transcription option support
- known model-family policy

## OpenAI Row

Status: complete for the current breaking line.

### Shared Contracts

- Language generation supports Responses and Chat Completions routes behind one
  `LanguageModel` adapter.
- Embeddings, images, speech, and transcription implement the direct provider
  contracts and expose response metadata through `ModelResponseMetadata`.
- Streaming emits provider stream events with unified response metadata,
  warnings, usage, finish reason, provider metadata, and explicit raw-chunk
  opt-in.
- Request body parsing follows the reference ownership split: provider package
  owns OpenAI wire vocabulary; transport owns response-body JSON coercion.
- JSON response coercion now goes through `openai_json_support.dart` for
  language, embedding, image, transcription, files, assistants, moderation, and
  Responses lifecycle helper clients.

### Provider-Owned Surface

- Responses API replay policy, stored item references, encrypted reasoning
  content, `phase`, MCP/code-interpreter/file-search tools, and lifecycle
  helper clients stay OpenAI-owned.
- Chat Completions compatibility policy, reasoning-model request conversion,
  OpenRouter online model rewrite, xAI/DeepSeek/OpenRouter profile options,
  service tier, metadata support, and logprob handling stay OpenAI-family owned.
- Files, moderation, assistants, and raw Responses lifecycle clients are native
  helper clients. They should not be promoted into shared provider contracts
  unless another provider exposes the same durable model.

### Shared Option Audit

- Shared `responseFormat` maps to OpenAI response-format policy and conflicts
  with OpenAI-specific response format options by design.
- Shared `reasoning` maps to OpenAI reasoning policy; provider-specific
  reasoning effort overrides shared reasoning with a warning when applicable.
- `topK` remains unsupported by OpenAI and should continue to warn or be
  ignored according to the route/profile policy rather than become a fake
  shared mapping.
- No new shared option belongs in `llm_dart_provider` from the OpenAI row.
  Current gaps are provider-owned or profile-owned.

### Metadata Audit

- Namespace is `openai` for OpenAI-owned provider metadata.
- Response id/model/timestamp/headers live in `ModelResponseMetadata`.
- Provider metadata retains Responses replay fields, output item ids, reasoning
  encrypted content, annotations, image revised prompts and token details, and
  transcription/image response details.
- Replay metadata flows back through explicit prompt-part provider options; raw
  provider metadata is not accepted as ordinary input customization.

## Google Row

Status: complete for the current breaking line.

### Shared Contracts

- Language generation supports Gemini `generateContent` and
  `streamGenerateContent` behind the direct `LanguageModel` adapter.
- Embeddings implement single and batch Google embedding routes with the direct
  `EmbeddingModel` contract and Vercel-aligned max embedding count.
- Images support both Imagen `predict` and Gemini `generateContent` image
  output/editing through the direct `ImageModel` contract.
- Speech supports Gemini TTS through the direct `SpeechModel` contract.
- Streaming emits unified text, reasoning, reasoning-file, file, source,
  tool-call, custom server-tool replay, response metadata, usage, warnings, and
  raw-chunk events.
- JSON response coercion now goes through `google_json_support.dart` for
  language, embedding, image, and speech response bodies.

### Provider-Owned Surface

- Gemini thought signatures, reasoning files, server-side tool call/replay,
  function-response replay, grounding metadata, cached content, safety settings,
  and Google native tools remain provider-owned.
- Imagen-specific image generation options and Gemini image editing options stay
  on typed `GoogleImageOptions` instead of becoming shared image options.
- Gemini TTS voice and multi-speaker policy remain `GoogleSpeechOptions`; shared
  speech fields unsupported by Gemini TTS are warning-dropped.
- Google transcription remains deferred because there is no implemented Google
  transcription adapter in this breaking line.

### Shared Option Audit

- Shared `responseFormat` maps to Google JSON schema response configuration and
  conflicts with `GoogleGenerateTextOptions.responseFormat` by design.
- Shared `reasoning` maps to Google thinking configuration for supported Gemini
  model families.
- `topK` is supported by Google language/speech generation where the underlying
  Gemini route accepts it; it should stay a shared option, not a provider-only
  escape hatch.
- No new shared option belongs in `llm_dart_provider` from the Google row.
  Current gaps are either already modeled as shared options or provider-owned.

### Metadata Audit

- Namespace is `google` for Google-owned provider metadata.
- Response id/model/timestamp/headers live in `ModelResponseMetadata`.
- Provider metadata retains Google response ids, model versions, usage metadata,
  prompt feedback, grounding metadata, finish messages/reasons, thought
  signatures, reasoning-file markers, function-response replay details, server
  tool replay details, revised prompts, and TTS/image generation route details.
- Replay metadata flows back through typed prompt-part provider options and
  Google custom parts; raw provider metadata is not accepted as ordinary input
  customization.

## Anthropic Row

Status: complete for the current breaking line.

### Shared Contracts

- Language generation supports Anthropic Messages `doGenerate` and SSE
  `doStream` behind the direct `LanguageModel` adapter.
- Streaming emits unified text, reasoning, tool input, tool call, source,
  file/code-execution replay, response metadata, usage, finish reason,
  warnings, and raw-chunk events.
- Token counting is exposed as an Anthropic-native helper on the language model
  because Anthropic's `/messages/count_tokens` shape is provider-specific.
- Files API support is exposed as a native helper client and as code-execution
  file-handle metadata/download helpers.
- JSON response coercion stays in `anthropic_api.dart`, which is already the
  neutral Anthropic API helper for URI, headers, beta merging, and response-body
  coercion.

### Provider-Owned Surface

- Anthropic beta header inference and merging, MCP client beta, interleaved
  thinking beta, extended cache TTL beta, files beta, code execution replay,
  deferred tool results, container/metadata/service tier, prompt cache control,
  and tool result file semantics remain provider-owned.
- Count tokens stays provider-owned. The shared core should not grow a token
  counting contract until at least two providers expose compatible semantics.
- Files stay provider-owned. The shared core should not grow a files contract
  until provider file references, upload lifecycle, download permissions, and
  beta/header policy can be modeled without Anthropic-specific behavior.
- Embedding, image, speech, and transcription remain deferred for Anthropic in
  this breaking line.

### Shared Option Audit

- Shared `reasoning` maps to Anthropic thinking policy through typed
  `AnthropicGenerateTextOptions`; Anthropic-specific thinking budget and
  interleaved thinking stay provider-owned.
- Shared `topK`, `topP`, temperature, stop sequences, and max output tokens map
  to Messages fields where compatible with thinking policy.
- `responseFormat` does not become a shared Anthropic structured-output
  contract in this row; Anthropic tool/json policy remains provider-owned until
  a stable shared shape is proven.
- No new shared option belongs in `llm_dart_provider` from the Anthropic row.

### Metadata Audit

- Namespace is `anthropic` for Anthropic-owned provider metadata.
- Response id/model/timestamp/headers live in `ModelResponseMetadata`.
- Provider metadata retains raw usage, container details, citations/sources,
  thinking signatures, server-tool/code-execution replay details, file ids, and
  token-count warnings where applicable.
- Replay metadata flows back through typed prompt-part provider options and
  Anthropic replay helper types; raw provider metadata is not accepted as
  ordinary input customization.

## Ollama Row

Status: complete for the current breaking line.

### Reference Posture

- `repo-ref/ai` does not include a first-party Ollama provider package. Its
  provider docs point to community providers, so this row aligns Ollama against
  the shared provider contracts and `provider-utils` ownership split rather
  than a first-party wire implementation.
- The Dart package intentionally keeps direct HTTP integration in-tree because
  local model catalog behavior, binary image resolution, and Ollama sampling
  policy are product-specific enough to stay provider-owned.

### Shared Contracts

- Language generation supports Ollama `/api/chat` behind the direct
  `LanguageModel` adapter.
- Embeddings support Ollama `/api/embed` behind the direct `EmbeddingModel`
  adapter. `maxEmbeddingsPerCall` remains unknown because Ollama does not
  publish a stable shared batch limit.
- Streaming decodes Ollama NDJSON chunks through transport UTF-8 mechanics and
  emits unified response metadata, reasoning, text, tool-call, finish, usage,
  provider metadata, and raw-chunk events.
- Shared JSON schema `responseFormat` maps to Ollama `format`. Unsupported
  shared response-format decoration fields warn and are dropped.
- Shared reasoning maps only to Ollama's boolean `think` toggle. Shared
  reasoning effort and budget are warning-dropped because Ollama has no
  compatible budget contract.
- JSON response coercion goes through `decodeOllamaJsonObject` in
  `ollama_api.dart`, preserving provider-readable diagnostics while
  `llm_dart_transport` owns parsing and object coercion.

### Provider-Owned Surface

- Local model catalog support (`/api/tags`) remains an Ollama-native helper and
  should not become a shared model registry contract.
- Binary/image prompt resolution remains provider-owned through
  `OllamaBinaryResolver` because Ollama expects base64 image payloads while the
  shared prompt contract can carry bytes, data URLs, and remote URLs.
- Ollama native sampling and runtime options such as `num_ctx`, `num_gpu`,
  `num_thread`, `num_batch`, `numa`, `keep_alive`, `raw`, and `reasoning`
  remain typed provider options.
- Image generation, speech, and transcription remain deferred for Ollama in
  this breaking line.

### Shared Option Audit

- `temperature`, `topP`, `topK`, `maxOutputTokens`, `seed`, and
  `stopSequences` map to Ollama chat `options`.
- `presencePenalty` and `frequencyPenalty` remain unsupported shared options
  for this provider and warn rather than silently pretending to map to an
  Ollama-specific equivalent.
- Provider `reasoning` overrides shared `options.reasoning` with an explicit
  compatibility warning.
- No new shared option belongs in `llm_dart_provider` from the Ollama row.
  Current gaps are provider-owned local runtime controls.

### Metadata Audit

- Namespace is `ollama` for Ollama-owned provider metadata.
- Response model and timestamp live in `ModelResponseMetadata`; Ollama chat
  responses do not expose a durable response id.
- Provider metadata retains created-at text, done reason, total/load/eval
  durations, prompt/eval duration counters, and embedding timing counters.
- Ollama has no replay metadata model comparable to OpenAI item ids, Google
  thought signatures, or Anthropic server-tool/file ids. Raw provider metadata
  is therefore observational only and not accepted as input customization.

## First Follow-Up

Use the same row format for ElevenLabs and the OpenAI-compatible family.
