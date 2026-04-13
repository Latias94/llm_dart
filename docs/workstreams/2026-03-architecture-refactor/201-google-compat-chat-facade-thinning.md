# 201 Google Compatibility Chat Facade Thinning

## Why This Slice Exists

After the earlier provider-boundary work, the remaining
`lib/src/compatibility/providers/google/chat.dart` file was still carrying too
many roles at once:

- legacy compatibility chat facade methods
- Google request-body shaping
- streamed SSE / JSON-array incremental parsing
- Google file-upload cache and multipart upload support
- response wrapper types

That mixture was no longer a correctness bug, but it still made the Google
compatibility shell look more like an implementation host than a compatibility
facade.

## What Changed

The public compatibility surface stays the same, but the internal ownership is
now split into narrower local helpers:

- `chat.dart`
  - thin compatibility facade and Google-specific error handling
- `google_chat_request_builder.dart`
  - request encoding and message/tool conversion
- `google_chat_stream_parser.dart`
  - stateful streamed delta parsing for SSE and JSON-array responses
- `google_chat_file_support.dart`
  - file upload, cache reuse, and multipart request support
- `google_chat_response.dart`
  - legacy response wrapper type

The old public types remain available through the same import path because
`chat.dart` re-exports:

- `GoogleFile`
- `GoogleChatResponse`

## Why This Is Better

- keeps the compatibility facade focused on routing and delegation
- isolates stateful stream parsing from request encoding
- isolates provider-specific file upload support from chat orchestration
- preserves the old public surface without another migration step
- makes future Google compatibility cleanup easier without inventing a new
  generic abstraction layer

## Boundary Decision

This slice intentionally does **not** try to turn the old Google compatibility
chat path into another modern package API.

The modern Google direction remains package-owned in `llm_dart_google`.

This work is only about making the root compatibility shell more honest and
maintainable while it still exists.

## Why This Matches The Reference Direction

The useful lesson from `repo-ref/ai` is ownership:

- request shaping should not stay mixed into facade orchestration
- stream parsing should not stay mixed into request construction
- provider-specific side concerns should not keep inflating the facade file

The Dart compatibility layer still stays much narrower and simpler than the
reference repository. The goal here is not structural symmetry. The goal is to
keep the shell readable and to stop mixed ownership from drifting back into one
large compatibility file.

## Validation

This slice is validated with:

- `dart analyze lib/src/compatibility/providers/google/chat.dart lib/src/compatibility/providers/google/google_chat_file_support.dart lib/src/compatibility/providers/google/google_chat_request_builder.dart lib/src/compatibility/providers/google/google_chat_response.dart lib/src/compatibility/providers/google/google_chat_stream_parser.dart test/providers/google/google_streaming_endpoint_test.dart test/providers/google/google_thinking_test.dart test/legacy_compatibility_test.dart`
- `dart test test/providers/google/google_streaming_endpoint_test.dart test/providers/google/google_thinking_test.dart test/legacy_compatibility_test.dart`

## Follow-Up

After this slice, the next worthwhile compatibility hotspot is more likely one
of these:

- `lib/src/compatibility/providers/anthropic/chat.dart`
- `lib/src/compatibility/providers/openai/client.dart`

The next step should again follow the same rule:

- thin mixed-ownership compatibility hosts first
- avoid symmetry-driven micro-files where the remaining file is already
  cohesive enough
