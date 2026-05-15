# Ollama Chat Codec Boundary

## Summary

The Ollama follow-up slice split the chat language-model implementation into
provider-local codec modules:

```text
packages/llm_dart_ollama/lib/src/ollama_chat_request_codec.dart
packages/llm_dart_ollama/lib/src/ollama_chat_response_codec.dart
packages/llm_dart_ollama/lib/src/ollama_chat_stream_codec.dart
packages/llm_dart_ollama/lib/src/ollama_tool_codec.dart
```

`OllamaLanguageModel` remains the public package implementation of the shared
`LanguageModel` contract. It now owns provider identity, capability discovery,
transport routing, headers, timeout/retry/cancellation forwarding, and stream
error mapping, while request projection and response parsing live in focused
provider-local modules.

This mirrors the useful provider-local shape from `repo-ref/ai` without adding
a public helper package:

```text
repo-ref/ai/packages/openai-compatible/src/chat/convert-to-openai-compatible-chat-messages.ts
repo-ref/ai/packages/openai-compatible/src/chat/openai-compatible-prepare-tools.ts
repo-ref/ai/packages/openai-compatible/src/chat/openai-compatible-chat-language-model.ts
```

The reference repository does not provide the same Ollama implementation shape,
so this slice applies the boundary lesson rather than copying provider code.

## Moved Responsibilities

`ollama_chat_request_codec.dart` owns:

- chat request body assembly for `/api/chat`
- shared option to Ollama option projection
- Ollama provider options such as `numCtx`, `numGpu`, `numThread`, `numBatch`,
  `numa`, `keepAlive`, `raw`, and provider `reasoning`
- shared reasoning toggle compatibility mapping to Ollama `think`
- response format schema projection
- prompt message projection for system, user, assistant, and tool messages
- image-only multimodal projection through bytes, data URIs, or
  `OllamaBinaryResolver`
- compatibility warnings for unsupported shared options and tool error replay

`ollama_chat_response_codec.dart` owns:

- non-stream response decoding
- text, reasoning, and tool-call content extraction
- usage mapping from Ollama token counters
- provider metadata mapping for duration and finish fields
- finish reason mapping

`ollama_chat_stream_codec.dart` owns:

- NDJSON byte-stream decoding
- UTF-8 buffering and pending-line flush behavior
- raw chunk event emission
- response metadata event emission
- reasoning and text start/delta/end event sequencing
- stream tool-call deduplication
- final finish event decoding

`ollama_tool_codec.dart` owns:

- function tool declaration encoding
- `toolChoice` compatibility warnings and `none` handling
- assistant tool-call replay encoding
- tool-call decoding
- tool input normalization
- tool output stringification

## Retained Responsibilities

`ollama_language_model.dart` still owns:

- `providerId` and `capabilityProfile`
- Ollama API URI and header construction
- model settings and API key/base URL normalization
- transport send and sendStream calls
- call-level header, timeout, retry, and cancellation forwarding
- stream error conversion to `ErrorEvent`

Catalog, embedding, and model-describer code remains outside this chat codec
split and keeps its current behavior.

## Provider Utils Decision Signal

This fourth provider slice still does not justify a public
`llm_dart_provider_utils` package.

The Ollama helpers are provider-local because their contracts are shaped by
Ollama runtime behavior:

- Ollama multimodal support accepts image payloads on the modern chat path, not
  the same file/content contract as OpenAI, Anthropic, or Google.
- Ollama `think`, `raw`, `keep_alive`, and local runtime sampling options are
  provider-native request fields.
- Ollama streams are newline-delimited JSON chunks rather than OpenAI SSE,
  Anthropic event streams, or Google stream envelopes.
- Ollama tool-choice support is automatic only, so shared `ToolChoice` values
  are warning policy rather than a reusable provider-neutral mapper.

Keep these helpers provider-local until another provider needs the same
independently testable behavior with the same validation rules and names.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages/llm_dart_ollama/lib/src/ollama_language_model.dart packages/llm_dart_ollama/lib/src/ollama_chat_request_codec.dart packages/llm_dart_ollama/lib/src/ollama_chat_response_codec.dart packages/llm_dart_ollama/lib/src/ollama_chat_stream_codec.dart packages/llm_dart_ollama/lib/src/ollama_tool_codec.dart
dart analyze packages/llm_dart_ollama
dart test packages/llm_dart_ollama/test
dart run tool/check_workspace_dependency_guards.dart
```

All commands passed.
