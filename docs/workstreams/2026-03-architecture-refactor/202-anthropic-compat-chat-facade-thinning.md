# 202 Anthropic Compatibility Chat Facade Thinning

## Why This Slice Exists

After the recent Google compatibility chat split, the remaining
`lib/src/compatibility/providers/anthropic/chat.dart` file still mixed several
different roles:

- compatibility chat facade methods
- token-count request shaping
- stateful streamed SSE parsing
- tool-call delta accumulation state
- legacy response wrapper types

That made the Anthropic compatibility shell larger than necessary and harder to
audit, even though much of the request-body logic had already moved into
`request_builder.dart`.

## What Changed

This slice keeps the public legacy surface stable while splitting the remaining
mixed ownership into narrower helpers:

- `chat.dart`
  - thin compatibility facade plus token-count fallback behavior
- `anthropic_chat_response.dart`
  - legacy response wrapper type
- `anthropic_chat_stream_parser.dart`
  - streamed SSE parsing and tool-call delta accumulation state
- `request_builder.dart`
  - now also owns token-count request shaping

The public legacy import path still exposes `AnthropicChatResponse` through
`chat.dart`.

## Why This Is Better

- keeps the compatibility facade focused on orchestration instead of parsing
- moves streamed parser state out of the facade file
- keeps token-count request shaping with the rest of Anthropic request shaping
- preserves the existing public compatibility import path
- reduces the chance that future Anthropic compatibility work drifts back into
  one large host file

## Boundary Decision

This is still a **compatibility-shell cleanup**, not a new modern API surface.

The modern Anthropic direction remains package-owned in `llm_dart_anthropic`.
This refactor only makes the root compatibility layer more honest while it
still exists.

## Why This Matches The Reference Direction

The useful structural lesson from `repo-ref/ai` is ownership:

- request shaping belongs with request shaping
- streamed parser state belongs with streamed parser state
- response wrapper types should not keep inflating facade files

The goal is not to copy the reference repository's file graph. The goal is to
keep the compatibility shell readable and prevent mixed responsibilities from
accumulating again.

## Validation

This slice is validated with:

- `dart analyze lib/providers/anthropic/chat.dart lib/src/compatibility/providers/anthropic/chat.dart lib/src/compatibility/providers/anthropic/anthropic_chat_response.dart lib/src/compatibility/providers/anthropic/anthropic_chat_stream_parser.dart lib/src/compatibility/providers/anthropic/request_builder.dart test/providers/anthropic/anthropic_provider_test.dart test/legacy_compatibility_test.dart`
- `dart test test/providers/anthropic/anthropic_provider_test.dart test/legacy_compatibility_test.dart`

## Follow-Up

After this slice, the next worthwhile compatibility hotspot is more likely one
of these:

- `lib/src/compatibility/providers/openai/client.dart`
- `lib/src/compatibility/providers/anthropic/request_builder.dart` only if a
  future change proves a narrower subdomain worth extracting

The next step should again favor mixed-ownership reduction over symmetry-driven
micro-file splitting.
