# Anthropic Result Codec Boundary

## Summary

The Anthropic result follow-up slice split non-stream Messages result decoding
into provider-local modules:

```text
packages/llm_dart_anthropic/lib/src/anthropic_result_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_result_content_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_result_tool_codec.dart
packages/llm_dart_anthropic/lib/src/anthropic_result_metadata.dart
packages/llm_dart_anthropic/lib/src/anthropic_result_util.dart
```

`AnthropicMessagesResultCodec` remains the stable public result facade used by
`AnthropicLanguageModel` and focused package tests. It now owns only top-level
content-block routing and final `GenerateTextResult` assembly. Content
projection, provider-tool result/replay projection, finish/usage/container
mapping, and provider metadata helpers live in focused provider-local modules.

This follows the provider-owned conversion shape from `repo-ref/ai` without
copying its TypeScript class graph:

```text
repo-ref/ai/packages/anthropic/src/anthropic-language-model.ts
repo-ref/ai/packages/anthropic/src/convert-anthropic-usage.ts
repo-ref/ai/packages/anthropic/src/map-anthropic-stop-reason.ts
repo-ref/ai/packages/anthropic/src/anthropic-message-metadata.ts
```

The Dart package keeps Anthropic result semantics provider-owned because the
wire vocabulary includes provider-native thinking, redacted thinking,
compaction, MCP, server tool calls, web-search/fetch replay, tool-search
replay, code-execution replay, and Anthropic-specific metadata.

## Moved Responsibilities

`anthropic_result_content_codec.dart` owns:

- text result content projection
- citation source projection for web and document citations
- thinking and redacted-thinking result projection
- compaction content projection
- fallback custom Anthropic result blocks

`anthropic_result_tool_codec.dart` owns:

- common `tool_use` result projection
- provider-executed `server_tool_use` result projection
- `mcp_tool_use` result projection
- tool descriptor tracking for later tool result blocks
- `mcp_tool_result`, web fetch/search, tool-search, and code-execution result
  projection
- custom replay payload shaping for provider-native tool results
- web-search source extraction from provider-tool result content

`anthropic_result_metadata.dart` owns:

- Anthropic stop-reason to unified finish-reason mapping
- usage token projection
- container metadata projection

`anthropic_result_util.dart` owns:

- provider-local map/list/string/int projection helpers
- Anthropic provider metadata construction and namespace extraction

## Retained Responsibilities

`anthropic_result_codec.dart` still owns:

- the stable `AnthropicMessagesResultCodec.decodeResponse(...)` facade
- top-level result content-block routing
- final `GenerateTextResult` assembly
- warning forwarding from request preparation

`anthropic_code_execution_replay.dart` remains public and unchanged because it
owns the typed execution replay model, file-handle parsing, and custom
part/prompt/event conversion surface.

`anthropic_tool_replay_encoder.dart` remains the request-side replay encoder
for converting replay custom prompt parts back into Anthropic wire blocks.

## Provider Utils Decision Signal

This slice still does not justify a public `llm_dart_provider_utils` package.

Some helper categories overlap with stream decoding, but their contracts remain
Anthropic-specific:

- result content projection preserves Anthropic-specific thinking,
  redacted-thinking, compaction, and citation metadata.
- provider-tool result replay uses Anthropic wire block names and replay
  payloads.
- code-execution replay is a public Anthropic typed model, not a generic tool
  replay contract.
- usage and container metadata intentionally carry raw Anthropic response
  details.

If future result and stream changes repeatedly need the exact same citation or
provider-tool replay implementation, a narrow Anthropic-local helper can be
revisited. A public cross-provider utility still has no stable shared
interface.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages\llm_dart_anthropic\lib\src\anthropic_result_codec.dart packages\llm_dart_anthropic\lib\src\anthropic_result_content_codec.dart packages\llm_dart_anthropic\lib\src\anthropic_result_metadata.dart packages\llm_dart_anthropic\lib\src\anthropic_result_tool_codec.dart packages\llm_dart_anthropic\lib\src\anthropic_result_util.dart packages\llm_dart_anthropic\test\anthropic_result_codec_test.dart
dart analyze packages\llm_dart_anthropic
dart test packages\llm_dart_anthropic\test\anthropic_result_codec_test.dart packages\llm_dart_anthropic\test\anthropic_code_execution_replay_test.dart
dart test packages\llm_dart_anthropic\test\anthropic_fixture_contract_test.dart
```

All commands passed during the implementation slice.
