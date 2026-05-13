# Focused Provider Stream Naming Migration

Date: 2026-05-13
Status: implemented

## What Landed

This slice migrates production provider-facing stream APIs from
`TextStreamEvent` naming to `LanguageModelStreamEvent` naming.

Changed areas:

- focused provider `LanguageModel.doStream(...)` implementations
- OpenAI stream codecs and streaming support helpers
- Google stream codec, custom part helpers, and replay helpers
- Anthropic stream codec and code-execution replay helper
- Ollama stream decode helpers
- `llm_dart_test` fake language model

Runtime, chat, UI projection, structured output, and HTTP chat transport still
use `TextStreamEvent`. That is intentional: this slice renames provider-facing
model-call surfaces only.

## Why This Matters

The previous slice added `LanguageModelStreamEvent` and an AI runtime adapter
boundary. This slice makes provider production code speak the provider-owned
name so future implementation work can move actual event class ownership
without rereading every provider codec.

Because `LanguageModelStreamEvent` is still a compatibility typedef, this is a
low-risk semantic rename rather than a behavior change.

## Files

- `packages/llm_dart_openai/lib/src/openai_language_model.dart`
- `packages/llm_dart_openai/lib/src/openai_chat_completions_codec.dart`
- `packages/llm_dart_openai/lib/src/openai_responses_codec.dart`
- `packages/llm_dart_openai/lib/src/openai_streaming_support.dart`
- `packages/llm_dart_openai/lib/src/openai_custom_part.dart`
- `packages/llm_dart_openai/lib/src/openai_custom_part_summary.dart`
- `packages/llm_dart_google/lib/src/google_language_model.dart`
- `packages/llm_dart_google/lib/src/google_stream_codec.dart`
- `packages/llm_dart_google/lib/src/google_custom_part.dart`
- `packages/llm_dart_google/lib/src/google_custom_part_summary.dart`
- `packages/llm_dart_google/lib/src/google_function_response_replay.dart`
- `packages/llm_dart_google/lib/src/google_server_tool_replay.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_language_model.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay.dart`
- `packages/llm_dart_ollama/lib/src/ollama_language_model.dart`
- `packages/llm_dart_test/lib/src/fake_language_model.dart`

## Validation

- `dart analyze packages/llm_dart_openai packages/llm_dart_google packages/llm_dart_anthropic packages/llm_dart_ollama packages/llm_dart_test packages/llm_dart_provider packages/llm_dart_ai`
- `dart test packages/llm_dart_openai/test/openai_chat_completions_stream_codec_test.dart packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart packages/llm_dart_openai/test/openai_responses_codec_test.dart`
- `dart test packages/llm_dart_google/test/google_stream_codec_test.dart packages/llm_dart_google/test/google_function_response_replay_test.dart packages/llm_dart_google/test/google_server_tool_replay_test.dart packages/llm_dart_google/test/google_custom_part_test.dart`
- `dart test packages/llm_dart_anthropic/test/anthropic_stream_codec_test.dart packages/llm_dart_anthropic/test/anthropic_code_execution_replay_test.dart packages/llm_dart_ollama/test/ollama_language_model_test.dart`

## Remaining Work

The old `TextStreamEvent` event classes and `TextStreamEventJsonCodec` still
live in `llm_dart_provider`. That is the next architectural boundary to split:

- provider model-call event serialization should move to a provider-named codec
- runtime full-stream serialization should become `llm_dart_ai` ownership
- runtime-only event classes should stop living in the provider package

Do this after the current naming slice is committed and covered, because
serialization and chat transport tests have broader blast radius.
