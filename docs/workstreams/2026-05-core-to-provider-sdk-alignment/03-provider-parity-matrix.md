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

## First Follow-Up

Populate the OpenAI row first because it is the largest surface and the
OpenAI-compatible family depends on it. Then use the same matrix fields for
Google, Anthropic, Ollama, and ElevenLabs.
