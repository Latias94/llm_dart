# Anthropic Chat Stream Support Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/anthropic/anthropic_chat_stream_parser.dart`
was already provider-local, but it still mixed several different stream
responsibilities in one class:

- SSE frame buffering
- event/data line extraction
- Anthropic stream event dispatch
- incremental tool-call input aggregation
- thinking delta mapping
- stop-reason completion mapping
- provider error payload mapping

That made the parser harder to reason about than the newer OpenAI chat and
Responses stream paths, where the public capability shell, request builder, and
stream parsing support are easier to distinguish.

The better ownership boundary is:

- `anthropic_chat_stream_parser.dart` stays the small facade used by
  `AnthropicChat`
- `anthropic_chat_stream_support.dart` owns SSE framing and Anthropic stream
  event semantics

## What Changed

Added:

- `lib/src/compatibility/providers/anthropic/anthropic_chat_stream_support.dart`

Kept as the facade:

- `lib/src/compatibility/providers/anthropic/anthropic_chat_stream_parser.dart`

The support file now owns:

- complete-line SSE frame buffering
- `event:` / `data:` frame extraction
- message-start and message-stop completion mapping
- content-block start/delta/stop handling
- thinking delta mapping
- incremental tool-use JSON accumulation
- Anthropic stream error payload to `LLMError` mapping

The parser now stays focused on:

- accepting raw transport chunks
- delegating SSE frame buffering to provider-local support
- decoding JSON data payloads
- delegating Anthropic event semantics to provider-local support
- preserving logging for malformed JSON chunks

## Why This Boundary Is Better

This keeps Anthropic streaming aligned with the broader refactor rule:

- request shaping belongs in a request builder
- streamed parsing state belongs in stream support
- public capability files should stay small orchestration facades

It also follows the `repo-ref/ai` lesson at the right granularity for this Dart
library: internal provider stream state is layered, but no new package or shared
core event abstraction is introduced just for Anthropic.

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/anthropic/anthropic_chat_stream_parser.dart lib/src/compatibility/providers/anthropic/anthropic_chat_stream_support.dart test/providers/anthropic/anthropic_chat_stream_support_test.dart`
- `dart test test/providers/anthropic/anthropic_chat_stream_support_test.dart`
- `dart test test/providers/anthropic`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
