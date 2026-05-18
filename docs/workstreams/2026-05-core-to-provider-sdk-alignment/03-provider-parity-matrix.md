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

## First Follow-Up

Use the same row format for Google, Anthropic, Ollama, ElevenLabs, and the
OpenAI-compatible family.
