# 205 OpenAI Chat Facade Thinning

## Why This Slice Exists

After thinning the OpenAI compatibility client and the Responses compatibility
host, the remaining `lib/src/compatibility/providers/openai/chat.dart` file
still mixed several different responsibilities:

- Chat Completions facade methods
- chat-specific request shaping
- stateful streamed delta parsing
- completion reconstruction
- legacy response wrapper ownership

That left the chat path heavier than the neighboring OpenAI compatibility
slices and made the remaining ownership less obvious than it needed to be.

## What Changed

This slice keeps the public `OpenAIChat` import path stable while splitting the
remaining roles into focused local helpers:

- `chat.dart`
  - thin compatibility facade and summary convenience
- `chat_request_builder.dart`
  - chat-specific request shaping, including OpenRouter `deepseek-r1`
    `include_reasoning` handling
- `chat_stream_parser.dart`
  - stateful streamed delta parsing and completion reconstruction
- `openai_chat_response.dart`
  - legacy response wrapper and non-streaming thinking extraction

`OpenAIChatResponse` remains available through the same public legacy import
path:

- `package:llm_dart/providers/openai/chat.dart`

## Why This Is Better

- keeps request shaping out of the facade file
- isolates streamed parser state from chat orchestration
- moves response-wrapper ownership out of the capability host
- preserves the stable public import path for existing compatibility callers
- makes the OpenAI compatibility chat and Responses slices follow the same
  local ownership rule without creating a new shared abstraction layer

## Boundary Decision

This remains a **compatibility-shell cleanup** only.

The root OpenAI chat implementation is still a migration-era shell. The goal
here is to keep that shell honest and maintainable, not to redefine the modern
provider-package direction.

## Why This Matches The Reference Direction

The useful lesson from `repo-ref/ai` is again ownership:

- request shaping should not stay mixed into the facade
- stateful stream parsing should not stay mixed into response wrapping
- response wrapper types should not keep inflating capability hosts

The Dart root compatibility layer still stays intentionally narrower than the
reference repository. The target is clearer ownership, not structural parity.

## Validation

This slice is validated with:

- `dart analyze lib/src/compatibility/providers/openai/chat.dart lib/src/compatibility/providers/openai/openai_chat_response.dart lib/src/compatibility/providers/openai/chat_request_builder.dart lib/src/compatibility/providers/openai/chat_stream_parser.dart test/providers/openai/openai_request_body_support_test.dart test/providers/openai/openai_stream_parsing_support_test.dart test/legacy_compatibility_test.dart`
- `dart test test/providers/openai/openai_request_body_support_test.dart test/providers/openai/openai_stream_parsing_support_test.dart test/legacy_compatibility_test.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
- `dart run tool/check_workspace_dependency_guards.dart`

## Follow-Up

After this slice, the next worthwhile OpenAI-family compatibility hotspot is
more likely one of these:

- `lib/src/compatibility/providers/openai/provider_compat.dart` if a later
  pass wants to separate pure delegation from convenience helpers like model
  checks or suggestion generation
- `lib/src/compatibility/providers/openai/audio.dart` only if a future change
  proves it has drifted back into mixed request / response / convenience
  hosting beyond what the current file shape honestly justifies

The main rule stays unchanged: cut mixed-ownership hosts first, and stop when
the remaining file is already cohesive enough.
