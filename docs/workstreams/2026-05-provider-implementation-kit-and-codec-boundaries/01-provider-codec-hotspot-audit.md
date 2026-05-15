# Provider Codec Hotspot Audit

## Current Signal

The package graph and runtime boundaries are now healthier than the provider
implementation interiors. The largest remaining files are concentrated around
provider codecs, stream parsing, replay, and provider-native helper clients.

First-pass hotspots:

| File | Approx. lines | Primary concern |
| --- | ---: | --- |
| `packages/llm_dart_openai/lib/src/openai_responses_codec.dart` | 1867 | Responses request/response/stream/custom-part/replay coupling |
| `packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart` | 1353 | message conversion, content block handling, files/replay coupling |
| `packages/llm_dart_openai/lib/src/openai_assistants.dart` | 1259 | provider-native lifecycle client breadth |
| `packages/llm_dart_openai/lib/src/openai_chat_completions_codec.dart` | 1236 | chat request/response/stream/tool mapping coupling |
| `packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart` | 852 | stream state machine, tool/use/result mapping, metadata projection |
| `packages/llm_dart_google/lib/src/google_generate_content_codec.dart` | 833 | content projection, tool/function calling, media/file mapping |
| `packages/llm_dart_ollama/lib/src/ollama_language_model.dart` | 833 | request building, stream decoding, option/capability mapping in one model |
| `packages/llm_dart_chat/lib/src/http_chat_transport_protocol_impl.dart` | 794 | transport protocol encoding; lower priority because it is not provider-owned |
| `packages/llm_dart_chat/lib/src/default_chat_session.dart` | 793 | chat runtime orchestration; lower priority after runtime boundary closure |
| `packages/llm_dart_ai/lib/src/serialization/text_stream_event_json_codec.dart` | 787 | AI runtime full-stream JSON; lower priority unless stream schema changes |

The provider files deserve priority because they are where new provider
features and provider-specific bug fixes will continue to land.

## Reference Repository Lessons

The reference `repo-ref/ai` repository provides a useful split pattern:

- `packages/provider` owns stable provider contracts.
- `packages/provider-utils` owns narrow implementation helpers such as
  `detect-media-type`, `resolve-provider-reference`, `schema`,
  `response-handler`, `parse-json-event-stream`, and
  `streaming-tool-call-tracker`.
- provider packages keep provider-specific conversion modules, for example
  Anthropic prompt conversion and tool preparation, Google message conversion
  and tool preparation, and OpenAI provider/config/tools.

The relevant lesson is:

- shared helpers should be small and behavior-focused
- provider-specific request semantics should remain provider-local
- tests should sit next to conversion helpers and fixtures
- utilities should not become runtime orchestration or transport ownership

## Dart-Specific Differences To Preserve

The Dart architecture should keep these deliberate differences:

- strongly typed provider options instead of untyped option bags
- provider capability profiles as first-class descriptors
- direct provider packages for focused dependencies
- provider-owned helper clients for files, voices, catalogs, moderation, and
  lifecycle APIs
- a model-first AI runtime API that apps can use without understanding provider
  codecs

The workstream should improve provider internals without making Dart users pay
for another app-facing API churn cycle.

## Initial Decomposition Candidates

### OpenAI Responses

Likely split boundaries:

- `openai_responses_request_codec.dart`
- `openai_responses_response_codec.dart`
- `openai_responses_stream_codec.dart`
- `openai_responses_tool_replay.dart`
- `openai_responses_custom_parts.dart`

Risk:

- Responses has the richest provider-native event vocabulary, so stream parsing
  must stay heavily tested before and after any split.

### Anthropic Messages

Likely split boundaries:

- `anthropic_prompt_codec.dart`
- `anthropic_content_blocks.dart`
- `anthropic_tool_replay.dart`
- `anthropic_file_references.dart`
- `anthropic_stop_and_usage_mapping.dart`

Risk:

- Anthropic's prompt/cache/file/tool semantics are provider-local. Splitting
  should preserve that locality instead of moving behavior into shared helpers
  too early.

### Google GenerateContent

Likely split boundaries:

- `google_content_projection.dart`
- `google_tool_codec.dart`
- `google_file_data_codec.dart`
- `google_finish_and_usage_mapping.dart`

Risk:

- Google has both Gemini and Vertex semantics. Avoid flattening those into
  provider-neutral helpers.

### Ollama Language Model

Likely split boundaries:

- `ollama_chat_request_builder.dart`
- `ollama_chat_stream_parser.dart`
- `ollama_tool_codec.dart`
- `ollama_option_mapping.dart`

Risk:

- Ollama is local-runtime shaped. Keep catalog and local model behavior
  provider-owned.

## Recommended First Slice

Start with a non-behavioral audit PR that adds no production code:

- freeze the split boundaries for OpenAI Responses
- list the tests that must remain green
- identify package-private helpers versus public helper candidates

Then implement the first production slice by extracting OpenAI Responses request
encoding or stream parsing, whichever has better fixture coverage at the time.
