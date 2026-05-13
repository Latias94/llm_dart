# Provider Runtime Dependency Guards

Date: 2026-05-13
Status: implemented

## What Landed

This slice expands `test/provider_stream_naming_guard_test.dart` from a naming
guard into a provider/runtime boundary guard.

It now checks:

- focused provider package libs do not use runtime stream names such as
  `TextStreamEvent` or `TextStreamEventJsonCodec`
- provider-facing packages do not place `llm_dart`, `llm_dart_ai`,
  `llm_dart_chat`, or `llm_dart_flutter` in runtime `dependencies`
- provider-facing package lib code does not import app/runtime/chat/root
  packages
- AI runtime's temporary legacy `provider.TextStreamEventJsonCodec` bridge is
  isolated to the single compatibility wrapper

This gives us a cheap tripwire before the real class move: provider packages
can keep typed provider options, provider-native replay helpers, and provider
wire codecs, but they cannot couple back to the app runtime.

## Validation

- `dart analyze test/provider_stream_naming_guard_test.dart`
- `dart test test/provider_stream_naming_guard_test.dart`

## Remaining Work

Once `TextStreamEvent` implementation classes move out of `llm_dart_provider`,
the guard should be tightened to also reject provider exports of runtime-only
event names from the provider package itself.
