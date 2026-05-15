# OpenAI Responses Codec Boundary Audit

## Current Entry Points

`OpenAILanguageModel` uses `OpenAIResponsesCodec` as the Responses route owner:

- `encodeRequest(...)` builds the request body and warnings before transport.
- `decodeGenerateResponse(...)` maps a JSON response to `GenerateTextResult`.
- `decodeStreamChunk(...)` maps parsed SSE JSON chunks to
  `LanguageModelStreamEvent`.

The transport, SSE framing, route selection, and profile routing already live
outside the codec. That is healthy. The remaining issue is that the codec file
still mixes too many provider-internal responsibilities in one class.

## Current Responsibility Map

`packages/llm_dart_openai/lib/src/openai_responses_codec.dart` currently owns:

| Area | Approx. lines | Current methods / types | Notes |
| --- | ---: | --- | --- |
| public codec facade | 13-138 | `OpenAIResponsesRequest`, `OpenAIResponsesStreamState`, `OpenAIResponsesCodec.encodeRequest`, `decodeGenerateResponse`, `decodeStreamChunk` | Should remain as the stable package-private facade used by `OpenAILanguageModel`. |
| top-level request body assembly | 140-298 | `_encodeRequest` | Mixes model capability policy, shared option warnings, include/logprob/reasoning resolution, provider options, tools, response format, and body construction. |
| prompt/replay request encoding | 299-802 | `_encodePromptMessage`, `_encodeAssistantMessage`, `_encodeToolMessage`, `_encodeUserPart`, `_joinTextParts` | Highest-value request split. This is where item references, `store`, `conversation`, replay metadata, file data, and compaction interact. |
| request compatibility policy | 803-970 | `_warnUnsupportedResponsesSharedOptions`, `_applyOpenAIReasoningCompatibility`, `_applyOpenAIServiceTierCompatibility`, `_resolveInclude`, `_encodeResponsesTopLogProbs` | Could move with request encoding, but keep policy visible through tests. |
| provider-native request helpers | 971-1257 | `_encodeOpenAICompactionItem`, `_openAIImageDetail`, `_encodeTools`, `_encodeToolChoice`, `_encodeResponseFormat`, `_encodeToolOutput`, `_encodeContentToolOutput*`, `_openAIFileId` | Mostly request-only and a good extraction candidate. |
| non-stream response decode | 1259-1416 | `_decodeGenerateResponse`, `_throwIfError`, `_mapFinishReason`, `_decodeUsage`, `_outputItems`, `_responseFinishReason` | Partly delegates output item projection to `openai_responses_support.dart`. |
| stream chunk dispatch and event mapping | 1418-2027 | `_handle*Chunk`, `_resolveTextId`, `_resolveReasoningId` | High-risk state machine. It uses shared OpenAI stream helpers and should not be the first production split. |
| local JSON helpers and timestamp/media helpers | 2029-2051 | `_asMap`, `_asList`, `_jsonListOrNull`, `_asString`, `_asInt`, `_decodeResponseTimestamp`, `_normalizeImageMediaTypeForDataUrl` | Some are duplicated elsewhere; keep private until repeated use proves stable helper value. |
| stream metadata adapter | 2053-2090 | `_ResponsesStreamMetadataAdapter` | Belongs with stream mapping if that later splits. |

## Existing Extracted Support

`openai_responses_support.dart` already owns several response-side helpers:

- message output projection
- reasoning output projection
- function-call output projection
- MCP approval and MCP call output projection
- custom output projection
- source annotation decoding and dedup keys
- response/item/stream metadata builders
- JSON argument fallback for function calls

`openai_streaming_support.dart` already owns cross-OpenAI stream state helpers:

- indexed tool-call accumulation
- text/reasoning start/delta/end event helpers
- tool input start/delta/end/error helpers
- logprob accumulation
- response metadata capture

Because these helpers already exist, the next split should avoid re-extracting
response projection. The current weak point is request encoding.

## Test Coverage Map

Current focused tests already cover the areas needed for a safe first split:

| Test file | Coverage |
| --- | --- |
| `openai_responses_codec_test.dart` | request encoding for user images/files/provider references, prompt part options, legacy metadata rejection, PDF URLs, structured tool outputs, assistant replay, item references, conversation skipping, MCP approval responses, non-stream response metadata, custom outputs |
| `openai_responses_stream_codec_test.dart` | stream mapping for response metadata, reasoning, text, function-call deltas, malformed tool input, source events, custom events, MCP approval/results, failed responses, image partial events |
| `openai_language_model_test.dart` | transport-level integration around Responses request bodies, provider options, built-in tools, reasoning compatibility, logprobs, replay, and streaming behavior |
| `openai_custom_part_test.dart` / `openai_custom_part_summary_test.dart` | app-facing parsing of OpenAI custom output parts |

The first implementation slice should keep these tests unchanged and add only
new tests if the extracted helper becomes directly testable.

## Recommended First Production Slice

Extract request encoding while preserving the current facade:

- keep `OpenAIResponsesCodec.encodeRequest(...)` public within the package
- add a package-private helper such as `OpenAIResponsesRequestEncoder`
- move request-only logic into `openai_responses_request_codec.dart`
- leave `decodeGenerateResponse(...)` and `decodeStreamChunk(...)` in the
  current codec for the first slice

Suggested moved responsibilities:

- `_encodeRequest`
- `_encodePromptMessage`
- `_encodeAssistantMessage`
- `_encodeToolMessage`
- `_encodeUserPart`
- request warning/policy helpers
- `_encodeOpenAICompactionItem`
- `_encodeTools`
- `_encodeToolChoice`
- `_encodeResponseFormat`
- `_encodeToolOutput` and content tool-output file helpers
- `_openAIImageDetail`
- `_openAIFileId`
- `_normalizeImageMediaTypeForDataUrl` if only request helpers need it

Suggested retained responsibilities in `openai_responses_codec.dart`:

- `OpenAIResponsesStreamState`
- `OpenAIResponsesCodec`
- `decodeGenerateResponse(...)` implementation
- stream chunk dispatch and handlers
- `_ResponsesStreamMetadataAdapter`

Implementation note: the production slice moved `OpenAIResponsesRequest` with
the request codec to avoid a cycle where `openai_responses_codec.dart` imports
the request helper while the request helper imports the request result type.

This makes the first split mostly mechanical but meaningful: the codec facade
continues to route request/response/stream behavior, while the request body
builder gets one reason to change.

## Candidate File Shape

First slice:

```text
packages/llm_dart_openai/lib/src/openai_responses_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_request_codec.dart
```

Possible later slices:

```text
packages/llm_dart_openai/lib/src/openai_responses_result_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_stream_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_metadata.dart
```

Do not create all files up front. Split only when the moved code has a clear
test boundary.

## Risks

### Replay Semantics

Assistant replay is request-side but depends on response-side provider metadata
from earlier calls. The extraction must preserve:

- item references when `store` is enabled
- full replay items when `store` is false
- skipping stored items when `conversation` is set
- encrypted reasoning and compaction metadata
- MCP approval response continuation

### Provider Options Versus Provider Metadata

The current request path intentionally rejects ordinary request-side
customization through `ProviderMetadata`. It uses typed prompt part options for
`imageDetail` and uses replay metadata only for provider-produced continuation
data. The extraction must not reintroduce metadata-driven request options.

### Shared Helper Temptation

Several helpers look generic, especially JSON/string/map helpers and media-data
encoding. Do not move them to a public utility package in the first slice. The
same behavior must appear in at least one more provider before that decision is
worth supporting publicly.

### Stream Parser Complexity

Responses stream parsing is the highest-risk area because it ties together:

- OpenAI event names
- text/reasoning lifecycle events
- function-call argument accumulation
- malformed tool input events
- source annotation deduplication
- MCP approval/tool result events
- final finish reason and usage metadata

Leave this for a later, stream-specific split after the request split proves
the pattern.

## Acceptance Criteria For The First Slice

The first implementation slice is acceptable when:

- `OpenAIResponsesCodec.encodeRequest(...)` remains the call site used by
  `OpenAILanguageModel`
- request encoding logic moves into a request-focused helper
- public OpenAI package exports do not change
- request encoding tests in `openai_responses_codec_test.dart` pass unchanged
- integration tests in `openai_language_model_test.dart` pass for Responses
  request bodies
- stream tests are not affected
- workspace dependency guards still pass

## Validation Commands

Run these after the first production split:

```powershell
dart test packages/llm_dart_openai/test/openai_responses_codec_test.dart
dart test packages/llm_dart_openai/test/openai_language_model_test.dart
dart test packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart
dart analyze packages/llm_dart_openai
dart run tool/check_workspace_dependency_guards.dart
```

Before claiming the workstream milestone, also run:

```powershell
dart run tool/release_readiness.dart
```

## Decision

The first production slice should be:

> Extract OpenAI Responses request encoding into a provider-local
> `openai_responses_request_codec.dart`, keeping `OpenAIResponsesCodec` as the
> stable package-private facade and leaving result/stream decoding untouched.

This is the best next move because it reduces real ownership coupling without
touching the more fragile stream parser or changing the public runtime API.
