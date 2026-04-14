# 204 OpenAI Responses Facade Thinning

## Why This Slice Exists

After thinning the OpenAI compatibility client, the remaining
`lib/src/compatibility/providers/openai/responses.dart` file still mixed too
many roles:

- Responses chat facade methods
- request-body shaping
- response and input-item endpoint query construction
- streamed delta parsing and completion reconstruction
- legacy response wrapper ownership

That shape still worked, but it kept the Responses compatibility path looking
like a mixed implementation host instead of a thinner facade over narrower
local helpers.

## What Changed

This slice keeps the public `OpenAIResponses` surface stable while splitting
the remaining ownership into focused helpers:

- `responses.dart`
  - thin compatibility facade plus CRUD / conversation orchestration
- `responses_request_builder.dart`
  - Responses request-body shaping and endpoint/query construction
- `responses_stream_parser.dart`
  - stateful streamed delta parsing and completion reconstruction
- `openai_responses_response.dart`
  - legacy response wrapper and thinking/tool-call extraction

The legacy public import path remains stable:

- `package:llm_dart/providers/openai/responses.dart`

`OpenAIResponsesResponse` also remains available through that same public path.

## Why This Is Better

- keeps endpoint and request shaping out of the facade body
- isolates stateful stream parsing from CRUD and conversation methods
- moves response wrapper ownership out of the capability host
- preserves the stable compatibility import path and response type access
- makes later Responses cleanup more incremental and less risky

## Boundary Decision

This slice is still a **root compatibility cleanup**, not a new modern
provider-package API.

The goal is to keep the root OpenAI Responses shell honest while it still
exists, without inventing another shared abstraction tier.

## Why This Matches The Reference Direction

The relevant lesson from `repo-ref/ai` is ownership:

- request and endpoint shaping should not stay mixed into the facade
- streamed parser state should not stay mixed into CRUD and conversation logic
- response wrapper types should not keep inflating the capability host

The Dart root compatibility layer remains intentionally less granular than the
reference repository. The point is clearer ownership, not file-count parity.

## Validation

This slice is validated with:

- `dart analyze lib/src/compatibility/providers/openai/responses.dart lib/src/compatibility/providers/openai/openai_responses_response.dart lib/src/compatibility/providers/openai/responses_request_builder.dart lib/src/compatibility/providers/openai/responses_stream_parser.dart test/providers/openai/openai_request_body_support_test.dart test/providers/openai/openai_responses_support_test.dart test/providers/openai/openai_responses_tool_call_streaming_test.dart test/providers/openai/openai_stream_parsing_support_test.dart`
- `dart test test/providers/openai/openai_request_body_support_test.dart test/providers/openai/openai_responses_support_test.dart test/providers/openai/openai_responses_tool_call_streaming_test.dart test/providers/openai/openai_stream_parsing_support_test.dart test/providers/openai/responses_stateful_test.dart test/legacy_compatibility_test.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `dart run tool/check_workspace_dependency_guards.dart`

## Follow-Up

After this slice, the next worthwhile OpenAI-family compatibility hotspot is
more likely one of these:

- `lib/src/compatibility/providers/openai/chat.dart` if a later change proves
  that the remaining request/stream/response ownership should be split the
  same way as Responses
- `lib/src/compatibility/providers/openai/provider_compat.dart` only if a
  future step needs to isolate provider-shell convenience helpers from pure
  delegation

The main rule stays the same: keep cutting mixed-ownership hosts first, and
avoid symmetry-driven extra files where the remaining module is already
cohesive enough.
