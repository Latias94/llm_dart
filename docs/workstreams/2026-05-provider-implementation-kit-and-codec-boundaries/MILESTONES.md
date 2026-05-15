# Milestones

## M1 - Hotspot And Boundary Freeze

Goals:

- audit the largest provider implementation files
- freeze the first decomposition order
- define helper publication criteria

Acceptance criteria:

- hotspot audit exists
- non-goals are explicit
- first provider slice is selected
- shared helper extraction criteria are written down

Current status:

- workstream scaffold created
- initial hotspot audit recorded from current source shape
- reference lessons from `repo-ref/ai` recorded without copying its package
  graph blindly

## M2 - OpenAI Responses First Slice

Goals:

- split one OpenAI Responses responsibility out of the large codec
- keep behavior unchanged
- strengthen fixture-based tests around the extracted boundary

Acceptance criteria:

- focused OpenAI tests pass
- extracted helper has a single reason to change
- public OpenAI facade remains stable
- release readiness remains green

Current status:

- OpenAI Responses codec boundary audit is documented.
- Request encoding has moved into provider-local
  `openai_responses_request_codec.dart`.
- `OpenAIResponsesCodec` remains the package-private facade used by
  `OpenAILanguageModel`.
- Focused OpenAI request, stream, language-model integration tests, package
  analysis, and workspace dependency guards pass for this slice.

## M3 - Second Provider Contrast Slice

Goals:

- apply the same boundary discipline to a non-OpenAI provider
- prove the pattern is not OpenAI-specific

Preferred candidates:

- Anthropic message/content/tool replay boundary
- Google content/tool/file projection boundary
- Ollama chat request/stream parser boundary

Acceptance criteria:

- focused provider tests pass
- provider-native behavior remains provider-owned
- no new provider runtime dependency violations

Current status:

- Anthropic was selected as the non-OpenAI contrast provider.
- Anthropic tool configuration has moved into provider-local
  `anthropic_tool_configuration.dart`.
- Google was added as a follow-up contrast slice after initial closure.
- Google GenerateContent prompt/content projection and tool configuration have
  moved into provider-local `google_content_projection.dart` and
  `google_tool_configuration.dart`.
- `AnthropicMessagesCodec` still owns message body assembly, prompt block
  projection, tool result replay, files, cache-control scanning, and beta
  discovery.
- `GoogleGenerateContentCodec` still owns top-level request assembly,
  generation config, response format, safety settings, cached content,
  candidate count warnings, and thinking config.
- Focused Anthropic messages tests, language-model integration tests, package
  analysis, workspace dependency guards, root boundary guard, and core
  compatibility guard pass for this slice.
- Focused Google GenerateContent, language-model, replay, result, and stream
  tests, package analysis, and workspace dependency guards pass for the
  follow-up slice.
- Ollama was added as a follow-up contrast slice after Google.
- Ollama chat request construction, non-stream response decoding, NDJSON stream
  parsing, and tool encoding/decoding have moved into provider-local
  `ollama_chat_request_codec.dart`, `ollama_chat_response_codec.dart`,
  `ollama_chat_stream_codec.dart`, and `ollama_tool_codec.dart`.
- `OllamaLanguageModel` now owns facade and transport orchestration only.
- Focused Ollama tests, package analysis, and workspace dependency guards pass
  for the follow-up slice.
- Anthropic stream was added as a follow-up stream-boundary contrast slice after
  Ollama.
- Anthropic Messages stream state, content-block mapping, tool input/result
  mapping, and finish/usage/metadata mapping have moved into provider-local
  `anthropic_stream_state.dart`, `anthropic_stream_content_codec.dart`,
  `anthropic_stream_tool_codec.dart`, `anthropic_stream_result_codec.dart`, and
  `anthropic_stream_util.dart`.
- `AnthropicStreamCodec` now owns top-level chunk dispatch, ping filtering, and
  provider error chunk conversion only.
- Focused Anthropic stream tests, full Anthropic package tests, package
  analysis, and workspace dependency guards pass for the follow-up slice.

## M4 - Provider Implementation Kit Decision

Goals:

- inventory helper duplication after at least two implementation slices
- decide internal-only versus public utility package

Acceptance criteria:

- repeated helpers are listed with provider users
- public `llm_dart_provider_utils` is either deferred with rationale or
  designed with a stable scope
- no utility package is created for one-provider convenience

Current status:

- Helper duplication after the OpenAI and Anthropic slices is documented.
- No public `llm_dart_provider_utils` package is justified for this workstream.
- No new internal shared helper module is justified yet; extracted helpers stay
  provider-local.
- The repeated helper candidates are either already owned by
  `llm_dart_provider` contracts or differ by provider wire semantics.
- The Google follow-up slice reinforces this decision because its content,
  provider-reference, native-tool, and Gemini 3 replay behavior is
  provider-local rather than a stable shared helper contract.
- The Ollama follow-up slice reinforces this decision because its local runtime
  options, image-only multimodal request shape, NDJSON stream parser, and
  automatic-only tool-choice warnings are provider-local rather than stable
  shared helper contracts.
- The Anthropic stream follow-up slice reinforces this decision because its
  content-block index state, incremental tool-input JSON accumulation,
  immediate provider tool results, custom replay payloads, and finish metadata
  are Anthropic stream semantics rather than stable shared helper contracts.

## M5 - Release Readiness And Closure

Goals:

- validate the provider-internal refactor across the whole workspace
- close the workstream with migration notes if public behavior changed

Acceptance criteria:

- focused provider tests pass
- workspace dependency guards pass
- full release readiness passes
- any public migration notes are updated

Current status:

- Full `dart run tool/release_readiness.dart` passed on
  2026-05-15T10:13:40 local time.
- Closure audit maps each required deliverable to code, docs, and validation
  evidence.
- No public behavior migration notes are required because the changes are
  provider-internal and keep existing package-private facades stable.
