# Anthropic Stream Codec Boundary

## Summary

The Anthropic stream follow-up slice split the Messages stream codec into
provider-local modules:

```text
packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_stream_state.dart
packages/llm_dart_anthropic/lib/src/anthropic_stream_content_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_stream_tool_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_stream_result_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_stream_util.dart
```

`AnthropicStreamCodec` remains the stable package stream facade used by
`AnthropicLanguageModel` and the existing focused tests. It now owns only
top-level chunk-type dispatch, ping filtering, and error chunk conversion while
message state, content-block mapping, tool-call/result mapping, and finish
metadata live in focused provider-local modules.

This applies the provider-local stream lessons from `repo-ref/ai` without
copying its package graph:

```text
repo-ref/ai/packages/anthropic/src/anthropic-language-model.ts
repo-ref/ai/packages/anthropic/src/convert-anthropic-usage.ts
repo-ref/ai/packages/anthropic/src/map-anthropic-stop-reason.ts
repo-ref/ai/packages/anthropic/src/anthropic-message-metadata.ts
repo-ref/ai/packages/provider-utils/src/parse-json-event-stream.ts
repo-ref/ai/packages/provider-utils/src/streaming-tool-call-tracker.ts
```

The Dart package keeps SSE parsing in transport/provider integration and keeps
Anthropic stream semantics provider-owned instead of publishing a shared stream
utility package.

## Moved Responsibilities

`anthropic_stream_state.dart` owns:

- response id, model id, raw finish reason, stop sequence, raw usage, container,
  and context-management accumulation
- content-block state keyed by Anthropic block index
- tool descriptors keyed by Anthropic tool-use id
- text, reasoning, and tool block state objects

`anthropic_stream_result_codec.dart` owns:

- `message_start` state updates
- response metadata event construction
- prepopulated tool-use block discovery from `message_start.content`
- `message_delta` usage, finish, stop sequence, container, and context
  management accumulation
- `message_stop` finish event construction
- Anthropic stop reason and usage mapping

`anthropic_stream_content_codec.dart` owns:

- `content_block_start`, `content_block_delta`, and `content_block_stop`
  projection
- text and compaction block lifecycle events
- thinking and redacted-thinking lifecycle events
- text, compaction, thinking, signature, tool input, and citation deltas
- citation source projection
- delegation from content blocks to Anthropic tool semantics

`anthropic_stream_tool_codec.dart` owns:

- prepopulated common tool calls from `message_start`
- common `tool_use`, provider-executed `server_tool_use`, and `mcp_tool_use`
  start handling
- tool input delta accumulation and JSON validation
- final `ToolInputEndEvent`, `ToolInputErrorEvent`, and `ToolCallEvent`
  construction
- immediate tool results for web fetch, web search, code execution,
  tool search, and MCP
- Anthropic custom replay payloads and web-search source events

`anthropic_stream_util.dart` owns shared provider-local JSON/object projection
and Anthropic provider metadata helpers used by the stream modules.

## Retained Responsibilities

`anthropic_stream_codec.dart` still owns:

- the stable `AnthropicStreamCodec.decodeChunk(...)` facade
- top-level Anthropic stream chunk dispatch
- `ping` chunk filtering
- provider error chunk conversion to `ErrorEvent`
- re-export of `AnthropicMessagesStreamState` for the existing package surface

`anthropic_language_model.dart` still owns:

- request preparation through `AnthropicMessagesCodec`
- SSE byte-stream parsing through `SseJsonChunkParser`
- raw chunk event emission
- transport sendStream wiring and transport error conversion
- provider headers, beta features, timeout, retry, and cancellation forwarding

Messages request encoding, result decoding, native tool configuration, files,
cache control, code-execution replay, and model capability behavior are outside
this stream split and keep their existing ownership.

## Provider Utils Decision Signal

This follow-up slice still does not justify a public
`llm_dart_provider_utils` package.

Anthropic stream helpers are provider-local because their contracts are shaped
by Anthropic Messages streaming behavior:

- content blocks are keyed by Anthropic block indexes and have provider-specific
  `text`, `compaction`, `thinking`, `redacted_thinking`, `tool_use`,
  `server_tool_use`, and `mcp_tool_use` semantics.
- tool input deltas are incremental JSON fragments and may become
  `ToolInputErrorEvent` instead of `ToolCallEvent`.
- immediate tool result blocks produce Anthropic-specific replay payloads for
  web fetch/search, tool search, code execution, and MCP.
- finish metadata carries Anthropic raw usage, stop sequence, container, and
  context-management response details.

Ollama also has a provider-local stream parser now, but its NDJSON chunks and
tool-call dedupe state are not the same contract as Anthropic content-block
state and tool-input accumulation.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart packages/llm_dart_anthropic/lib/src/anthropic_stream_state.dart packages/llm_dart_anthropic/lib/src/anthropic_stream_util.dart packages/llm_dart_anthropic/lib/src/anthropic_stream_result_codec.dart packages/llm_dart_anthropic/lib/src/anthropic_stream_tool_codec.dart packages/llm_dart_anthropic/lib/src/anthropic_stream_content_codec.dart
dart analyze packages/llm_dart_anthropic
dart test packages/llm_dart_anthropic/test
dart run tool/check_workspace_dependency_guards.dart
```

All commands passed.
