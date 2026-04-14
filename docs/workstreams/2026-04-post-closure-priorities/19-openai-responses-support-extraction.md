# OpenAI Responses Support Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/openai/responses.dart` already had several
good internal boundaries:

- `responses_request_builder.dart` owns request and endpoint shaping
- `responses_stream_parser.dart` owns streamed event parsing
- `openai_responses_response.dart` owns response normalization

Even so, the facade still hosted a second cluster of non-streaming lifecycle
and stateful-conversation orchestration:

- background response creation
- response retrieval
- response deletion and error wrapping
- background response cancellation
- input-item listing
- conversation continuation
- conversation forking
- summary prompt/result helpers

That made the file more than a chat/streaming facade. The better ownership
boundary is:

- `responses.dart` stays the public compatibility facade
- `openai_responses_support.dart` owns non-streaming lifecycle and helper
  orchestration

## What Changed

Added:

- `lib/src/compatibility/providers/openai/openai_responses_support.dart`

Kept as the facade:

- `lib/src/compatibility/providers/openai/responses.dart`

The support file now owns:

- non-streaming response creation
- background response creation
- response lifecycle operations
- delete error wrapping into `OpenAIResponsesError`
- input item listing
- continue/fork conversation orchestration
- summary prompt building and response text extraction
- non-streaming response parsing through `OpenAIResponsesResponse`

The facade now stays focused on:

- implementing `ChatCapability` and `OpenAIResponsesCapability`
- streaming through `OpenAIResponsesStreamParser`
- delegating non-streaming lifecycle operations to provider-local support

## Why This Boundary Is Better

This keeps the public `OpenAIResponses` compatibility object stable while
making its internal responsibilities clearer.

It also preserves the already-good layered shape:

- request builder
- stream parser
- response parser
- lifecycle support
- public facade

This mirrors the `repo-ref/ai` lesson without copying package granularity:
complex provider APIs should be internally layered, but the public Dart
compatibility surface can stay stable.

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/openai/responses.dart lib/src/compatibility/providers/openai/openai_responses_support.dart test/providers/openai/openai_responses_support_test.dart`
- `dart test test/providers/openai/openai_responses_support_test.dart`
- `dart test test/providers/openai/openai_request_body_support_test.dart test/providers/openai/openai_stream_parsing_support_test.dart test/providers/openai/openai_responses_tool_call_streaming_test.dart`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
