# Provider Implementation Kit Audit

## Current Source Findings

The adapter splits have made repeated provider implementation needs visible:

- provider option type resolution
- header merging
- base URL normalization
- route URI construction
- JSON object coercion
- byte and base64 response decoding
- multipart body construction
- media type and filename inference
- response metadata construction
- provider metadata namespace construction
- SSE, NDJSON, and UTF-8 stream decoding
- transport error projection

The previous policy deferred publishing `llm_dart_provider_utils` until at
least two providers proved a stable seam. That threshold is now met for some
helpers, but not all helpers should become public API.

## Reference Comparison Targets

Use these `repo-ref/ai` areas as comparison material:

- `packages/provider-utils/src/post-to-api.ts`
- `packages/provider-utils/src/response-handler.ts`
- `packages/provider-utils/src/parse-json.ts`
- `packages/provider-utils/src/parse-json-event-stream.ts`
- `packages/provider-utils/src/convert-to-form-data.ts`
- `packages/provider-utils/src/media-type-to-extension.ts`
- `packages/provider-utils/src/without-trailing-slash.ts`
- `packages/provider-utils/src/parse-provider-options.ts`

## Candidate Helper Categories

### Strong Candidates For Internal Shared Helpers

- JSON object response coercion with provider-specific response names
- case-insensitive header lookup
- immutable provider metadata namespace construction helpers
- media type to file extension inference
- base64 and byte list validation helpers
- header merge helpers that preserve provider defaults and call overrides

These already appear across multiple providers and have low provider-specific
policy content.

### Keep Local For Now

- route URI construction
- model-family route selection
- provider-specific request body construction
- provider-specific response metadata field names
- provider-specific warning policy
- provider-specific option conflict rules

These encode product policy and should stay close to the provider adapter.

### Public Utility Package Candidates

No helper should be made public until:

- at least two provider packages use it
- tests define the helper contract independently from one provider
- the helper has no hidden provider policy
- publishing it would reduce user-facing or provider-author friction

The likely path is an internal implementation kit first, then public
`llm_dart_provider_utils` only if external provider authors need the same
contract.

## Proposed First Slice

Write a helper inventory table before extracting code:

- helper name
- current duplicate locations
- proposed owner
- public/private status
- tests needed
- reason not to keep local

This avoids extracting shallow pass-through modules that merely move complexity
away from the provider that owns it.

## Inventory

| Helper | Duplicate locations | Owner | Public status | Decision |
| --- | --- | --- | --- | --- |
| JSON object response coercion | OpenAI language/non-text, Google language/embedding/image/speech, Anthropic API/files/token count, Ollama language/embedding/catalog/stream, ElevenLabs transcription/voice catalog | `llm_dart_transport` | Public transport utility, not provider-utils | Use `JsonObjectResponseDecoder` behind provider-named wrappers so providers keep readable diagnostics while parsing/error normalization lives in one module. |
| SSE JSON chunk parsing | OpenAI, Google, Anthropic stream adapters; transport tests already cover SSE framing | `llm_dart_transport` | Public transport utility | Keep provider stream codecs responsible for provider event vocabulary; transport owns byte/SSE/JSON frame mechanics. |
| UTF-8 stream decoding | Transport stream helpers and streaming tests | `llm_dart_transport` | Public transport utility | Keep shared; providers should not hand-roll split-codepoint handling. |
| Multipart body construction | OpenAI image/transcription/files, Anthropic files, ElevenLabs transcription | `llm_dart_transport` | Public transport utility | Keep shared builder; provider request modules still own field names and required form policy. |
| Base64 bytes and data URL encoding | OpenAI prompt/file paths, Google binary parts and image/speech responses, Anthropic content encoder, Ollama image prompts | Provider-local for now | Internal only | Patterns are similar but provider policy differs: media type defaults, accepted file kinds, and data URL shape are provider-owned. Revisit after provider parity rows identify identical contracts. |
| Header lookup and merge helpers | OpenAI files, Anthropic files, provider-specific API helpers | Provider-local for now | Internal only | Similar helper shape, but merge precedence and beta/header filtering are provider policy. |
| Provider metadata namespace construction | Google, ElevenLabs, OpenAI Chat/Responses, Anthropic result/stream, Ollama embedding/chat | Provider-local helpers around `ProviderMetadata.forNamespace` | Internal only | Keep package-local helper names because field ownership is provider policy, but require every provider implementation to route namespace construction through `ProviderMetadata.forNamespace`. |

## Implemented First Slice

- Deepened `JsonObjectResponseDecoder` in `llm_dart_transport` so it accepts
  any `Map` with string keys and returns `Map<String, Object?>`.
- Kept provider-named wrappers (`decodeOpenAIJsonObject`,
  `decodeGoogleJsonObject`, `decodeAnthropicJsonObject`,
  `decodeOllamaJsonObject`) as the provider-facing seam while deleting their
  duplicated `jsonDecode` and map coercion implementation.
- Migrated OpenAI language/non-text, Google language/embedding/image/speech,
  Anthropic API, Ollama API, and ElevenLabs transcription/voice catalog JSON
  body parsing to the transport helper.
- Kept ElevenLabs field validation local while separating response-body
  coercion behind `decodeElevenLabsJsonObject`, matching the provider-named
  wrapper pattern used by the other providers.
- Added transport-level tests for generic maps, non-string keys, and non-object
  JSON responses so the shared helper has its own contract.

## Provider Metadata Namespace Slice

- Migrated OpenAI Chat Completions, OpenAI Responses, Anthropic result, and
  Anthropic stream metadata helpers from raw `ProviderMetadata({...})`
  construction to `ProviderMetadata.forNamespace(...)`.
- Kept provider-local helper names because metadata field selection is still
  provider policy and should stay near each provider adapter.
- Added `tool/check_provider_metadata_namespace_guards.dart` and wired it into
  release readiness so provider implementation packages cannot reintroduce raw
  `ProviderMetadata` namespace maps.

## Provider Option And Replay Metadata Slice

- Compared `repo-ref/ai/packages/provider-utils/src/parse-provider-options.ts`
  with the Dart typed option design. Vercel validates provider-owned options
  under provider namespaces; Dart keeps compile-time provider option types and
  rejects wrong-provider options at adapter entrypoints.
- Documented the provider option precedence policy in the parity matrix:
  shared cross-provider fields win, provider options fall back for the same
  shared semantic, provider options override model settings for provider-owned
  knobs, reasoning-like native overrides warn, and response-format double
  configuration throws.
- Added speech regression coverage for OpenAI and ElevenLabs so shared
  `outputFormat`, `instructions`, `language`, and `speed` remain the primary
  request interface when provider options also supply equivalent fields.
- Removed the shallow `mergeProviderReplayMetadata` pass-through helper.
  Replay metadata now has one shared extraction helper,
  `providerReplayMetadataFromOptions`, which keeps request-side replay behavior
  explicit instead of looking like a generic metadata merge.
- Extended the provider replay metadata guard to fail if the old replay helper
  alias is reintroduced, and verified release readiness includes the replay
  guard command.

## Provider Utils Decision

Keep `llm_dart_provider_utils` deferred for now.

`repo-ref/ai` centralizes JSON parsing, response handlers, form-data helpers,
and stream parsing in `packages/provider-utils`. The Dart split already has a
more precise owner for the proven mechanics:

- `llm_dart_transport` owns response-body coercion, multipart bodies, SSE, and
  UTF-8 stream mechanics.
- Provider packages own field validation, route policy, provider option
  conflicts, response metadata names, and product-specific helper clients.

Do not create an internal predecessor package yet. The current deep helpers can
live in transport without forcing a new shallow module. Revisit a public
`llm_dart_provider_utils` package only when external provider authors need a
stable helper contract that is not transport-specific.

## Follow-Up Candidates

- Audit whether OpenAI moderation and assistant/file local response coercion can
  reuse the OpenAI non-text wrapper without making those clients depend on
  language-model support modules.
- Compare provider binary/media helpers and decide whether a small
  `DataUrlEncoder` or media-type normalization helper would be deep enough to
  justify a shared module.
- Audit stream parser call sites to ensure provider stream codecs only own
  provider event vocabulary, not byte/SSE/UTF-8 mechanics.
