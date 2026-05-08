# llm_dart_core

Compatibility-focused core entrypoints for `llm_dart`.

This package is the shared compatibility layer for the modern workspace.
Provider-facing contracts, UI projection, and serialization codecs now live in
`llm_dart_provider`; app-facing runtime helpers now live in `llm_dart_ai`.
`llm_dart_core` keeps the historical entrypoints as compatibility re-exports.

## What This Package Keeps

`llm_dart_core` keeps three related compatibility areas:

- compatibility re-exports for provider contracts from `llm_dart_provider`
- compatibility re-exports for AI runtime helpers from `llm_dart_ai`
- compatibility re-exports for shared stream/UI projection and serialization
  types such as
  `TextStreamEvent`, `ChatUiMessage`, `ChatUiStreamChunk`, `ChatMessageMapper`,
  and the JSON codecs for prompt/UI/event transport

## What This Package Does Not Own

This package does not own:

- new provider-facing contracts, UI models, or serialization codecs
- new app-facing generation helpers, runners, or structured output primitives
- HTTP and Dio transport mechanics
- chat/session persistence and controller orchestration
- Flutter widget/controller adapters
- provider-specific request codecs, custom parts, or provider-native feature
  policy

Use the higher packages for those responsibilities:

- `llm_dart_transport`
- `llm_dart_chat`
- `llm_dart_flutter`
- `llm_dart_provider`
- `llm_dart_ai`
- provider packages such as `llm_dart_openai`, `llm_dart_google`, and
  `llm_dart_anthropic`

## Internal Ownership Map

The package should be read as these groups:

- **Provider compatibility** - old core paths re-export provider contracts
  owned by `llm_dart_provider`
- **Runtime compatibility** - old core paths re-export generation helpers,
  runners, and structured output primitives owned by `llm_dart_ai`
- **Stream/UI compatibility** - old core paths re-export `TextStreamEvent`,
  `ChatUiMessage`, `ChatUiStreamChunk`, and `ChatMessageMapper` from
  `llm_dart_provider`
- **Serialization compatibility** - old core paths re-export prompt/UI/event
  codecs and protocol markers from `llm_dart_provider`

## Focused Entrypoints

The broad compatibility barrel remains, but it now composes the focused
entrypoints:

- `package:llm_dart_core/llm_dart_core.dart`

For narrower imports, use:

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

These entrypoints are additive and non-breaking. They clarify ownership without
splitting the compatibility package. The historical barrel stays only as a
migration shim.

## When To Use This Package Directly

Use `llm_dart_core` directly when you are maintaining code that still needs:

- historical core import paths during migration
- compatibility tests for old core paths
- packages that cannot move to the focused entrypoints in one step

For new provider implementations, prefer `llm_dart_provider`.

For new framework-neutral generation utilities, prefer `llm_dart_ai`.

If you need chat/session orchestration, prefer `llm_dart_chat`.

If you need Flutter state/controller adapters, prefer `llm_dart_flutter`.

## Design Rule

`llm_dart_core` is now intentionally a compatibility package.

New implementation ownership should move to the focused packages:

- provider-facing contracts -> `llm_dart_provider`
- shared UI projection and serialization -> `llm_dart_provider`
- framework-neutral runtime helpers -> `llm_dart_ai`
- chat/session orchestration -> `llm_dart_chat`
- Flutter adapters -> `llm_dart_flutter`
