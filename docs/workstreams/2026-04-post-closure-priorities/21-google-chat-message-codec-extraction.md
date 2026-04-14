# Google Chat Message Codec Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/google/google_chat_request_builder.dart`
was cohesive as a request builder, but it still carried two separable
responsibilities:

- top-level request-body and generation-config shaping
- provider-specific message, tool, and tool-choice payload encoding

That made the builder larger than necessary and mixed configuration policy with
wire-format codecs for multimodal parts and tool replay.

The better ownership boundary is:

- `google_chat_request_builder.dart` owns request body composition and
  generation configuration
- `google_chat_message_codec.dart` owns message, tool, and tool-choice payload
  encoding

## What Changed

Added:

- `lib/src/compatibility/providers/google/google_chat_message_codec.dart`

Kept as the request builder:

- `lib/src/compatibility/providers/google/google_chat_request_builder.dart`

The codec now owns:

- text message part conversion
- inline image conversion and unsupported-image fallbacks
- inline document/audio/video file conversion and oversize fallbacks
- image URL fallbacks
- tool-call replay as Google `functionCall` parts
- tool-result replay as Google `functionResponse` parts
- function declaration conversion
- Google tool-choice mapping and missing-tool fallback

The request builder now stays focused on:

- system prompt insertion
- system-message filtering for the compatibility path
- generation config shaping
- safety settings
- tool array assembly
- web-search tool insertion

## Why This Boundary Is Better

This matches the broader refactor direction without over-splitting packages:

- provider message codecs stay provider-local
- request builders keep endpoint-level request composition
- the public `GoogleChat` facade remains unchanged
- Flutter-facing and shared-core models do not need new Google-specific fields

The split also makes future Google multimodal/tool payload changes easier to
test without coupling every case to generation-config behavior.

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/google/google_chat_request_builder.dart lib/src/compatibility/providers/google/google_chat_message_codec.dart test/providers/google/google_chat_message_codec_test.dart`
- `dart test test/providers/google/google_chat_message_codec_test.dart`
- `dart test test/providers/google`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
