# llm_dart_chat

Pure Dart chat session and transport abstractions for `llm_dart`.

This package owns the reusable chat runtime:

- `ChatSession`
- `ChatTransport`
- `DefaultChatSession`
- `DirectChatTransport`
- `HttpChatTransport`
- snapshot and persistence codecs
- common chat message mapping helpers

The persistence helper in this package is intentionally session-oriented:

- `ChatPersistenceAdapter.saveSnapshot(...)`
- `ChatPersistenceAdapter.saveSession(...)`
- `ChatPersistenceAdapter.restoreSession(...)`

Flutter-only controller convenience stays in
`package:llm_dart_flutter/llm_dart_flutter.dart`.

It depends only on:

- `llm_dart_core`
- `llm_dart_transport`

That makes it suitable for:

- CLI apps
- server-side Dart backends
- framework-neutral chat orchestration
- Flutter adapters that want to build on the same runtime layer

## Runnable Example

For a framework-neutral session example that uses:

- `DefaultChatSession`
- `DirectChatTransport`
- `ToolExecutionRegistry`
- `ChatPersistenceAdapter`

see:

- `example/chat_runtime.dart`

If you need Flutter `ValueNotifier` integration, use
`package:llm_dart_flutter/llm_dart_flutter.dart`, which wraps this package with
`ChatController` and a controller-aware persistence adapter.
