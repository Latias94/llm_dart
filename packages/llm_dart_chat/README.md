# llm_dart_chat

Pure Dart chat session and transport abstractions for `llm_dart`.

This package owns the reusable chat runtime:

- `ChatSession`
- `ChatTransport`
- `DefaultChatSession`
- `ChatUiStreamReader`
- `DirectChatTransport`
- `HttpChatTransport`
- snapshot and persistence codecs
- compatibility re-exports for chat-runtime-oriented imports

The persistence helper in this package is intentionally session-oriented:

- `ChatPersistenceAdapter.saveSnapshot(...)`
- `ChatPersistenceAdapter.saveSession(...)`
- `ChatPersistenceAdapter.restoreSession(...)`

Flutter-only controller convenience stays in
`package:llm_dart_flutter/llm_dart_flutter.dart`.

It depends only on:

- `llm_dart_provider`
- `llm_dart_transport`

That makes it suitable for:

- CLI apps
- server-side Dart backends
- framework-neutral chat orchestration
- Flutter adapters that want to build on the same runtime layer

Recommended adoption order:

- start with `DefaultChatSession` plus `DirectChatTransport` when the app can
  call a concrete model directly
- switch to `HttpChatTransport` when routing, keys, audit policy, or tool
  execution should stay backend-owned
- use `ChatPersistenceAdapter` when you need durable session snapshots
- reach for `ChatUiStreamReader` only when you already have a
  `Stream<ChatUiStreamChunk>` and do not want the full session/runtime layer
- move up to `llm_dart_flutter` only when the UI needs `ValueNotifier`-style
  controller wiring

## Direct Chunk Stream Reading

If you already have a `Stream<ChatUiStreamChunk>` and do not want the full
`DefaultChatSession`, use:

- `ChatUiStreamReader`
- `readChatUiStream(...)`

The reader keeps the same stream-first contract:

- projected persistent message snapshots on the main stream
- `stepEvents` for `StepStartEvent` and `StepFinishEvent` boundaries
- `stepFinishStream` for the existing finish-only convenience path
- `transientDataParts` for runtime-only `data-*` signals
- `result` plus finish-state convenience futures for final inspection

It also supports optional validation hooks for direct chunk-stream consumers:

- `messageMetadataValidator`
  - validates merged message metadata before start/patch/finish metadata chunks
    are applied
- `dataPartValidator`
  - validates both persistent and transient `DataUiPart`s before projection or
    side-channel delivery

## Runnable Example

For a framework-neutral session example that uses:

- `DefaultChatSession`
- `DirectChatTransport`
- `ToolExecutionRegistry`
- `ChatPersistenceAdapter`

see:

- `example/chat_runtime.dart`
- `example/http_backend_hint_mapping.dart`
  - shows how a client can send app-owned metadata through
    `HttpChatTransport` while a backend maps those hints into provider-specific
    invocation options

If you need Flutter `ValueNotifier` integration, use
`package:llm_dart_flutter/llm_dart_flutter.dart`, which wraps this package with
`ChatController` and a controller-aware persistence adapter.

## HTTP Backend Hint Mapping

`HttpChatTransport` deliberately stays provider-neutral. It serializes shared
prompt state, shared `GenerateTextOptions`, stream protocol selection, and
app-owned metadata. It does not serialize raw `ProviderInvocationOptions`.

Use `metadata` and `prepareSendMessagesRequest` when a client needs to pass
backend-owned routing hints:

```dart
final session = DefaultChatSession(
  transport: HttpChatTransport(
    endpoint: Uri.parse('https://backend.example/chat'),
    transport: transportClient,
    prepareSendMessagesRequest: (context) {
      return HttpChatTransportPreparedSendMessagesRequest(
        payload: HttpChatTransportRequestPayload(
          chatId: context.payload.chatId,
          prompt: context.payload.prompt,
          generateOptions: context.payload.generateOptions,
          streamProtocol: context.payload.streamProtocol,
          metadata: {
            ...context.payload.metadata,
            'providerProfile': 'openai-web-search',
          },
        ),
      );
    },
  ),
);
```

The backend should decode `HttpChatTransportRequestPayload`, map app-owned
metadata such as `providerProfile` into typed provider options, and return SSE
frames encoded with `HttpChatTransportServerAdapter`.

Run the self-contained in-process demo with:

```bash
dart run packages/llm_dart_chat/example/http_backend_hint_mapping.dart
```

## Message Mapping Layers

`ChatUiMessage` and `ChatUiPart` remain the source of truth. Use
`ChatMessageMapper` only when a CLI, server-rendered UI, or framework-neutral
adapter wants stable cross-provider summaries such as:

- `text`
- `reasoningText`
- `toolParts`
- `sources`
- `fileParts`
- `warnings`
- `errors`

`ChatMessageMapper` now lives in `llm_dart_provider` as part of the shared UI
model layer and is re-exported here for chat-runtime users that prefer to stay
on a single package import path.

If a pure Dart application also needs provider-owned inspection, compose the
shared mapper with a provider package instead of widening `llm_dart_chat`
itself:

- `package:llm_dart_openai/llm_dart_openai.dart`
  - `OpenAIMessageMapper` for response/item/source/tool metadata, custom parts,
    logprobs-aware part inspection, and `mapComposed(...)`
- `package:llm_dart_google/llm_dart_google.dart`
  - `GoogleMessageMapper` for thought signatures, response-part metadata,
    source metadata, Google custom-part inspection, and `mapComposed(...)`

That keeps the runtime/session layer provider-neutral while still allowing rich
provider-specific rendering where applications need it.
