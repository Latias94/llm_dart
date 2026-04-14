# 203 OpenAI Compatibility Client Thinning

## Why This Slice Exists

After the recent Google and Anthropic compatibility chat thinning passes, the
remaining `lib/src/compatibility/providers/openai/client.dart` file was still
carrying too many different responsibilities:

- OpenAI-compatible message encoding
- tool-result replay expansion for legacy chat messages
- stateful SSE chunk boundary reconstruction
- provider-specific HTTP error adaptation
- HTTP request execution and logging

That shape still worked, but it kept the compatibility client acting as a
mixed implementation host instead of a thinner facade over narrower local
helpers.

## What Changed

This slice keeps the public `OpenAIClient` API stable while splitting internal
ownership into focused helpers:

- `client.dart`
  - thin compatibility client facade for request execution, logging, and the
    stable public helper methods
- `client_message_support.dart`
  - message encoding and tool-result replay expansion
- `client_sse_support.dart`
  - stateful SSE chunk parsing and boundary reconstruction
- `client_error_support.dart`
  - provider-specific HTTP error decoding and status mapping

The public legacy import path remains unchanged:

- `package:llm_dart/providers/openai/client.dart`

Existing callers still use:

- `OpenAIClient.convertMessage(...)`
- `OpenAIClient.buildApiMessages(...)`
- `OpenAIClient.parseSSEChunk(...)`
- `OpenAIClient.handleDioError(...)`

## Why This Is Better

- keeps request-shaping helpers out of the transport host
- isolates mutable SSE buffer state from the HTTP client facade
- isolates OpenAI-specific error decoding from request execution
- preserves the stable public compatibility API and test anchors
- leaves the remaining weight in `client.dart` more explicit: request
  execution, logging, and public facade methods

## Boundary Decision

This slice does **not** introduce a new shared client abstraction.

The root package still keeps `OpenAIClient` as a compatibility-oriented host.
The goal here is only to stop mixed ownership from accumulating inside one
large client file while the legacy shell still exists.

## Why This Matches The Reference Direction

The useful lesson from `repo-ref/ai` is ownership, not package granularity:

- message encoding should not stay mixed with transport execution
- stream boundary reconstruction should not stay mixed with request helpers
- provider-specific error adaptation should not stay mixed with the entire
  client surface

The Dart root compatibility layer remains intentionally smaller and less
granular than the reference repository. The goal is a more honest shell, not
structural imitation.

## Validation

This slice is validated with:

- `dart analyze lib/src/compatibility/providers/openai/client.dart lib/src/compatibility/providers/openai/client_message_support.dart lib/src/compatibility/providers/openai/client_sse_support.dart lib/src/compatibility/providers/openai/client_error_support.dart lib/src/compatibility/providers/openai/chat.dart lib/src/compatibility/providers/openai/responses.dart lib/src/compatibility/providers/openai/completion.dart test/providers/openai/message_conversion_test.dart test/providers/openai/openai_client_error_test.dart test/providers/openai/openai_stream_parsing_support_test.dart test/integration/memorial_on_dispatching_troops_streaming_test.dart`
- `dart test test/providers/openai/message_conversion_test.dart test/providers/openai/openai_client_error_test.dart test/providers/openai/openai_request_body_support_test.dart test/providers/openai/openai_stream_parsing_support_test.dart test/integration/memorial_on_dispatching_troops_streaming_test.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `dart run tool/check_workspace_dependency_guards.dart`

## Follow-Up

After this slice, the next worthwhile OpenAI-family compatibility hotspot is
more likely one of these:

- keep thinning the residual request-execution host inside
  `lib/src/compatibility/providers/openai/client.dart` only if a later change
  proves a smaller transport-helper split is genuinely useful
- re-check `chat.dart` and `responses.dart` only when a future change creates
  a new mixed-ownership hotspot instead of forcing more symmetry-driven splits

The main rule stays the same: reduce mixed ownership first, and avoid
micro-files that do not buy a clearer boundary.
