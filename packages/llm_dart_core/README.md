# llm_dart_core

Compatibility core entrypoints for existing `llm_dart` users.

New applications should normally start with the root package:
`package:llm_dart/llm_dart.dart`. Use `llm_dart_core` directly when you are
maintaining code that already imports historical core paths and you want a
smaller compatibility dependency during migration.

## What It Re-exports

This package keeps older core import paths available for:

- provider contracts from `llm_dart_provider`
- generation helpers from `llm_dart_ai`
- shared stream and UI projection types
- prompt, text-stream, and chat-UI JSON codecs

## Entrypoints

The broad compatibility barrel is:

- `package:llm_dart_core/llm_dart_core.dart`

Narrower imports are also available:

- `package:llm_dart_core/foundation.dart`
  - warnings, errors, usage, metadata, options, cancellation, JSON schema,
    prompt/content parts, and tool definitions
- `package:llm_dart_core/model.dart`
  - self-contained model specifications, capability helpers, runners, and raw
    stream events
- `package:llm_dart_core/ui.dart`
  - shared UI message, chunk, mapper, and accumulator contracts
- `package:llm_dart_core/serialization.dart`
  - prompt, UI, and stream-event JSON codecs plus related serialized data
    contracts

## When To Use It

Use `llm_dart_core` directly when you are maintaining code that still needs:

- historical core import paths during migration
- compatibility tests for old core paths
- packages that cannot move to the focused entrypoints in one step

For new code, choose the more specific package:

- `llm_dart_provider` for shared model/provider contracts
- `llm_dart_ai` for generation helpers
- `llm_dart_chat` for chat sessions and transports
- `llm_dart_flutter` for Flutter controller adapters
- focused provider packages for provider-specific options and helpers
