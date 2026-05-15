# OpenAI Responses Stream Codec Boundary

## Summary

The OpenAI Responses stream follow-up slice split the remaining stream-heavy
parts of `openai_responses_codec.dart` into provider-local modules:

```text
packages/llm_dart_openai/lib/src/openai_responses_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_stream_state.dart
packages/llm_dart_openai/lib/src/openai_responses_stream_event_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_stream_tool_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_stream_result_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_stream_util.dart
```

`OpenAIResponsesCodec` remains the stable provider-local facade used by
`OpenAILanguageModel` and the existing focused tests. It now owns only request
delegation, non-stream response delegation, and stream chunk delegation. The
state machine, chunk dispatch, text/reasoning/source/custom event mapping,
tool-call delta tracking, finish/usage/error mapping, and response metadata
mapping live in focused provider-local modules.

This follows the useful reference lesson from `repo-ref/ai` without copying its
package graph:

```text
repo-ref/ai/packages/openai/src/responses/openai-responses-language-model.ts
repo-ref/ai/packages/openai/src/responses/map-openai-responses-finish-reason.ts
repo-ref/ai/packages/provider-utils/src/streaming-tool-call-tracker.ts
```

The Dart package keeps the stream helper boundary OpenAI-local because the
Responses stream vocabulary, metadata shape, MCP events, built-in tool custom
parts, source annotations, and replay behavior are provider semantics.

## Moved Responsibilities

`openai_responses_stream_state.dart` owns:

- `OpenAIResponsesStreamState`
- OpenAI Responses annotation de-duplication state
- inheritance from the existing OpenAI-family stream accumulator

`openai_responses_stream_event_codec.dart` owns:

- top-level Responses stream chunk dispatch
- text start/delta/end event projection
- reasoning summary start/delta/end event projection
- source annotation event projection and duplicate suppression
- content-part done handling, including text-end metadata and logprobs
- partial image custom stream events
- output-item done routing for messages, function calls, MCP approval
  requests, MCP calls, reasoning, and custom provider items

`openai_responses_stream_tool_codec.dart` owns:

- function-call output item start handling
- `response.function_call_arguments.delta` accumulation
- tool input start/delta/end event construction
- malformed JSON tool-input error projection
- final `ToolCallEvent` construction from tracked function-call arguments

`openai_responses_stream_result_codec.dart` owns:

- non-stream Responses result decoding
- Responses error object conversion
- `response.created` metadata capture
- terminal `response.completed`, `response.incomplete`, and
  `response.failed` handling
- finish reason mapping
- usage mapping
- terminal response metadata event and finish event construction

`openai_responses_stream_util.dart` owns:

- provider-local map/list/string/int projection helpers
- Responses timestamp and raw finish reason extraction
- stream text/reasoning id resolution
- stream metadata adapter used by the event, tool, and result codecs

## Retained Responsibilities

`openai_responses_codec.dart` still owns:

- the stable `OpenAIResponsesCodec` facade
- request delegation to `OpenAIResponsesRequestCodec`
- non-stream result delegation to `decodeOpenAIResponsesGenerateResponse`
- stream chunk delegation to `decodeOpenAIResponsesStreamChunk`
- re-export of `OpenAIResponsesStreamState` for the existing package-private
  source import surface

`openai_language_model.dart` still owns:

- selecting the Responses path
- transport send/generate wiring
- SSE parsing and raw stream event plumbing
- warnings, timeout, retry, cancellation, and provider option forwarding

The unified `LanguageModelStreamEvent` vocabulary, Responses replay/custom
parts, MCP behavior, built-in tools, source annotations, logprobs, and
provider metadata behavior are unchanged.

## Provider Utils Decision Signal

This slice still does not justify a public `llm_dart_provider_utils` package.

The closest reference helper is Vercel AI SDK's streaming tool-call tracker.
The Dart code already has OpenAI-family stream helpers in
`openai_streaming_support.dart`, and the new Responses-specific modules only
add provider-local dispatch, metadata, source annotation, MCP, partial-image,
and terminal response behavior.

That is not the same contract as the already-completed Anthropic stream split
or Ollama NDJSON stream split:

- OpenAI Responses tool calls are keyed by output indexes and `call_id`.
- Anthropic stream state is keyed by content-block indexes and tool-use ids.
- Ollama stream state is driven by newline-delimited JSON chunks and local
  runtime semantics.

The shared helper trigger remains unchanged: revisit only if at least two
non-OpenAI providers need the same stream tool-call accumulator contract with
the same lifecycle and event semantics.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages\llm_dart_openai\lib\src\openai_responses_codec.dart packages\llm_dart_openai\lib\src\openai_responses_stream_state.dart packages\llm_dart_openai\lib\src\openai_responses_stream_util.dart packages\llm_dart_openai\lib\src\openai_responses_stream_event_codec.dart packages\llm_dart_openai\lib\src\openai_responses_stream_tool_codec.dart packages\llm_dart_openai\lib\src\openai_responses_stream_result_codec.dart
dart analyze packages\llm_dart_openai
dart test packages\llm_dart_openai\test\openai_responses_stream_codec_test.dart packages\llm_dart_openai\test\openai_responses_codec_test.dart packages\llm_dart_openai\test\openai_language_model_test.dart
dart run tool\check_workspace_dependency_guards.dart
```

All commands passed on 2026-05-15T12:05:06+08:00.
