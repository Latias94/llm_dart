# Root Chat Entrypoint Boundary

## Goal

After splitting the reusable runtime into `llm_dart_chat`, the next question is
whether application code should import that workspace package directly or
whether the root `llm_dart` package should expose a focused chat entrypoint.

This note freezes the answer.

## Reference Comparison

`repo-ref/ai` keeps a focused root package entry for app-facing UI work.

The useful lesson is not package-count parity. The useful lesson is that the
main package can expose a thin, intentional application-facing entrypoint
without becoming the implementation home for framework adapters.

For `llm_dart`, the equivalent is not a Flutter re-export. It is a pure Dart
chat-runtime barrel.

## Decision

The root package should expose:

- `package:llm_dart/chat.dart`

That entrypoint should stay a thin pure Dart shell that re-exports:

- `llm_dart_chat`
- `core.dart`
- `transport.dart`
- the stable `AI` facade

That entrypoint must not re-export:

- `llm_dart_flutter`
- `ChatController`
- any Flutter-only adapter or `foundation`-dependent type

## Why This Boundary Fits `llm_dart`

This gives the repository three clear app-facing choices:

- `package:llm_dart/llm_dart.dart`
  - general root facade plus compatibility surface
- `package:llm_dart/chat.dart`
  - focused pure Dart chat runtime
- `package:llm_dart_flutter/llm_dart_flutter.dart`
  - Flutter-specific controller and adapter surface

That shape is intentionally more compact than the Vercel AI SDK package split,
but it preserves the same important separation:

- pure runtime entrypoint
- framework adapter entrypoint
- implementation ownership staying below the entrypoints

## Dependency Implications

This decision does not change the dependency direction:

- `llm_dart_chat` stays the owner of the reusable runtime
- `llm_dart_flutter` stays above `llm_dart_chat`
- the root package remains a facade layer

The root package may depend on `llm_dart_chat` to provide the focused entry, but
it still must not absorb runtime implementation back from that package.

## Documentation And Migration Guidance

Recommended guidance after this freeze:

- use `package:llm_dart/chat.dart` for pure Dart chat applications
- use `package:llm_dart_flutter/llm_dart_flutter.dart` when Flutter adapters
  such as `ChatController` are needed
- keep `package:llm_dart/llm_dart.dart` as the broader root entrypoint and
  compatibility shell
- do not merge `chat.dart` back into the wide `llm_dart.dart` barrel if that
  would recreate ambiguous exports or blur the focused-entrypoint boundary

## Non-Goals

This decision does not mean:

- Flutter should move back into the root package
- the root package should mirror every workspace package with a new entrypoint
- `llm_dart_chat` should stop existing as the true runtime owner

## Status

This boundary is now implemented through:

- `lib/chat.dart`
- the root `pubspec.yaml` dependency on `llm_dart_chat`
- root-level entrypoint tests that validate the pure Dart chat surface
