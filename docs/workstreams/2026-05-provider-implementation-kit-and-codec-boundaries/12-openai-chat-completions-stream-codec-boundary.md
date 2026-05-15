# OpenAI Chat Completions Stream Codec Boundary

## Summary

The OpenAI Chat Completions follow-up slice split stream and result decoding
out of `openai_chat_completions_codec.dart` into provider-local modules:

```text
packages/llm_dart_openai/lib/src/openai_chat_completions_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_stream_state.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_stream_event_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_stream_tool_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_stream_result_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_stream_util.dart
```

`OpenAIChatCompletionsCodec` remains the stable provider-local facade used by
`OpenAILanguageModel` and OpenAI-compatible family profiles such as DeepSeek,
OpenRouter, Groq, and xAI. It now owns request encoding plus result/stream
delegation. Stream state, event projection, tool-call delta tracking,
finish/usage/error mapping, logprobs, and response metadata mapping live in
focused provider-local modules.

This mirrors the useful reference lesson from `repo-ref/ai` while keeping the
Dart package's OpenAI-family compatibility policy explicit:

```text
repo-ref/ai/packages/openai/src/chat/openai-chat-language-model.ts
repo-ref/ai/packages/openai/src/chat/convert-to-openai-chat-messages.ts
repo-ref/ai/packages/provider-utils/src/streaming-tool-call-tracker.ts
```

The split deliberately does not merge chat-completions with Responses. The two
wire protocols still differ: chat-completions streams `choices[].delta`, uses
fixed text/reasoning ids, and supports the OpenAI-compatible subset; Responses
streams output items, content parts, MCP/built-in tool items, annotations, and
terminal response objects.

## Moved Responsibilities

`openai_chat_completions_stream_state.dart` owns:

- `OpenAIChatCompletionsStreamState`
- xAI/open-compatible source de-duplication state
- inheritance from the OpenAI-family stream accumulator

`openai_chat_completions_stream_event_codec.dart` owns:

- chat-completions stream chunk decoding
- response metadata event emission
- top-level provider error chunk conversion
- xAI citation/source event projection
- text and reasoning delta event projection
- terminal text/reasoning end events
- final `FinishEvent` construction

`openai_chat_completions_stream_tool_codec.dart` owns:

- `choices[].delta.tool_calls` accumulation
- streamed tool input start/delta event construction
- final tool input end, malformed JSON input error, and `ToolCallEvent`
  construction

`openai_chat_completions_stream_result_codec.dart` owns:

- non-stream chat-completions response decoding
- assistant text/reasoning output projection through
  `OpenAIChatCompletionsSupport`
- non-stream tool-call and citation projection
- error object conversion
- finish reason, usage, logprobs, timestamp, and response metadata mapping

`openai_chat_completions_stream_util.dart` owns:

- provider-local map/list/string/int projection helpers
- first-choice, logprobs, timestamp, finish, usage, text delta, and reasoning
  delta helpers
- chat-completions stream metadata adapter

## Retained Responsibilities

`openai_chat_completions_codec.dart` still owns:

- the stable `OpenAIChatCompletionsCodec` facade
- chat-completions request encoding
- prompt message projection for the narrow OpenAI-compatible subset
- request-side compatibility warnings for OpenAI, DeepSeek, and OpenAI-family
  chat-completions options
- tool declaration and tool-choice request encoding
- response-format request encoding
- result delegation to `decodeOpenAIChatCompletionsGenerateResponse`
- stream delegation to `decodeOpenAIChatCompletionsStreamChunk`
- re-export of `OpenAIChatCompletionsStreamState` for the existing
  package-private source import surface

`openai_language_model.dart` still owns route selection, transport send/generate
wiring, SSE parsing, raw stream event plumbing, warnings, timeout, retry,
cancellation, and provider option forwarding.

## Provider Utils Decision Signal

This slice still does not justify a public `llm_dart_provider_utils` package.

Chat-completions and Responses both use the OpenAI-family stream primitives in
`openai_streaming_support.dart`, but their endpoint-local contracts remain
different. The extracted chat-completions helpers are shaped by:

- `choices[].delta` events
- fixed `text_0` and `reasoning_0` stream ids
- `tool_calls[].index` accumulation
- xAI citation arrays
- OpenAI-compatible provider namespaces
- chat-completions usage and finish-reason field names

Those behaviors are not the same contract as Responses output items,
Anthropic content-block indexes, Ollama NDJSON chunks, or Google content
parts. Keep the helper provider-local unless a future non-OpenAI provider needs
the same accumulator and event lifecycle.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages\llm_dart_openai\lib\src\openai_chat_completions_codec.dart packages\llm_dart_openai\lib\src\openai_chat_completions_stream_state.dart packages\llm_dart_openai\lib\src\openai_chat_completions_stream_util.dart packages\llm_dart_openai\lib\src\openai_chat_completions_stream_tool_codec.dart packages\llm_dart_openai\lib\src\openai_chat_completions_stream_result_codec.dart packages\llm_dart_openai\lib\src\openai_chat_completions_stream_event_codec.dart
dart analyze packages\llm_dart_openai
dart test packages\llm_dart_openai\test\openai_chat_completions_stream_codec_test.dart packages\llm_dart_openai\test\openai_language_model_test.dart
dart run tool\check_workspace_dependency_guards.dart
```

All commands passed on 2026-05-15T12:28:31+08:00.

`openai_chat_completions_codec_test.dart` does not exist in the current test
suite; it was not used as validation evidence.
