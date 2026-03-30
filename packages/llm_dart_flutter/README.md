# llm_dart_flutter

Flutter-facing chat transport and session abstractions for `llm_dart`.

This package is the UI-side layer above the shared `llm_dart_core` model API.
It does not add another provider abstraction. It turns stable model stream
semantics into an application-friendly chat session surface for Flutter.

The package is intentionally small:

- no prebuilt chat widgets
- no framework lock-in
- no storage backend
- no provider-specific API flattening

## What This Package Owns

`llm_dart_flutter` is responsible for the stateful UI boundary:

- `ChatTransport`
  - bridge from a direct model stream or a remote backend into session chunks
- `DirectChatTransport`
  - uses a local `LanguageModel`
- `HttpChatTransport`
  - connects Flutter to a backend over SSE
- `ChatSession`
  - session contract for send, stop, regenerate, tool output, approval, resume,
    and snapshot export
- `DefaultChatSession`
  - default session implementation above `ChatTransport`
- `ChatController`
  - `ValueNotifier<ChatState>` wrapper for widget integration
- `ChatPersistenceAdapter`
  - thin snapshot codec bridge above app-owned storage
- `ChatMessageMapper`
  - extracts common render summaries from `ChatUiMessage`

What stays outside this package:

- provider configuration
- typed provider options
- prompt and result model definitions
- raw transport implementation details that belong to providers or servers

## Layer Model

The recommended architecture is:

1. `llm_dart` selects and configures a provider model.
2. `llm_dart_core` defines prompt, stream, result, and UI message semantics.
3. `llm_dart_flutter` owns session state, transport adaptation, persistence
   boundaries, and widget-friendly control surfaces.

This keeps the unified layer focused on stable model semantics while still
leaving room for provider-owned features through:

- `CallOptions.providerOptions`
- `ProviderMetadata`
- `CustomUiPart`
- backend-owned HTTP chunk metadata when needed

## Direct Model Example

Use `DirectChatTransport` when Flutter can call the model directly.

```dart
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

Future<void> main() async {
  final controller = ChatController(
    session: DefaultChatSession(
      transport: DirectChatTransport(
        model: llm.AI.openai(
          apiKey: 'your-openai-key',
        ).chatModel('gpt-4.1-mini'),
      ),
    ),
  );

  controller.addListener(() {
    final state = controller.state;
    if (state.messages.isEmpty) {
      return;
    }

    final mapped = const ChatMessageMapper().map(state.messages.last);
    print('status=${state.status}');
    print('assistantText=${mapped.text}');
  });

  await controller.sendMessage(
    ChatInput.text('Write a short haiku about Flutter widgets.'),
  );

  await controller.close();
}
```

## Remote Backend Example

Use `HttpChatTransport` when API keys, auditing, caching, tool execution, or
compliance concerns require a backend.

```dart
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

Future<void> main() async {
  final controller = ChatController(
    session: DefaultChatSession(
      transport: HttpChatTransport(
        endpoint: Uri.parse('https://api.example.com/chat'),
        transport: DioTransportClient(),
        headers: const {
          'authorization': 'Bearer your-session-token',
        },
      ),
    ),
  );

  await controller.sendMessage(
    ChatInput.text('Summarize the latest release notes.'),
    options: const ChatRequestOptions(),
  );

  await controller.close();
}
```

`HttpChatTransport` expects:

- request envelopes encoded by `HttpChatTransportRequestJsonCodec`
- SSE frames containing `HttpChatTransportChunkJsonCodec` payloads
- optional resume tokens for reconnect support

The transport currently serializes `GenerateTextOptions`, but does not serialize
`CallOptions.timeout`, `CallOptions.headers`, or `CallOptions.providerOptions`.
Backend-specific transport behavior should be configured on the transport or on
the backend itself.

## Persistence Example

Storage stays application-owned. The package only provides snapshot encoding and
restoration helpers.

```dart
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

final class InMemoryChatStore implements ChatPersistenceStore {
  final Map<String, Object?> _storage = {};

  @override
  Future<Object?> readSnapshot(String chatId) async => _storage[chatId];

  @override
  Future<void> writeSnapshot(String chatId, Object? snapshotEnvelope) async {
    _storage[chatId] = snapshotEnvelope;
  }

  @override
  Future<void> deleteSnapshot(String chatId) async {
    _storage.remove(chatId);
  }
}

Future<void> saveAndRestore(
  ChatController controller,
  ChatTransport transport,
) async {
  final adapter = ChatPersistenceAdapter(
    store: InMemoryChatStore(),
  );

  await adapter.saveController(controller);

  final restored = await adapter.restoreController(
    controller.state.chatId,
    createController: (snapshot) => ChatController(
      session: DefaultChatSession.fromSnapshot(
        transport: transport,
        snapshot: snapshot,
      ),
    ),
  );

  await restored?.close();
}
```

## Message Mapping Example

`ChatUiMessage` already contains the full structured message. Use
`ChatMessageMapper` only when the UI wants convenient summaries for common
render paths.

```dart
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

void renderLatest(ChatController controller) {
  if (controller.messages.isEmpty) {
    return;
  }

  final mapped = const ChatMessageMapper().map(controller.messages.last);

  print(mapped.text);
  print(mapped.reasoningText);
  print(mapped.toolParts.length);
  print(mapped.sources.length);
  print(mapped.fileParts.length);
  print(mapped.dataParts.length);
  print(mapped.warnings.length);
  print(mapped.errors.length);
}
```

Prefer rendering directly from `message.parts` when the UI already understands
the richer part model.

## Tool and Approval Flows

`DefaultChatSession` supports the baseline interactive loop needed by chat UIs:

- send user messages
- stream assistant messages
- pause on client-executed tools
- inject tool output with `addToolOutput`
- pause on approval requests
- respond with `respondToolApproval`
- wait for the current assistant step to finish collecting local tool output and approval responses before continuing the next turn
- stop active generation
- resume reconnectable HTTP sessions after transport errors

Provider-executed tool behavior remains provider-owned. The session layer only
models stable tool and approval state transitions that a Flutter UI needs to
render.

## Design Rules

- Unify stable model semantics, not every provider surface.
- Keep provider-specific features in typed provider options, metadata, or
  custom parts.
- Keep storage application-owned.
- Keep Flutter dependencies out of `llm_dart_core`.
- Keep this package framework-neutral beyond Flutter `foundation`.

## Non-Goals

This package does not try to provide:

- a widget library
- a local database
- a BLoC, Riverpod, or Provider integration layer
- a backend implementation
- a new provider abstraction on top of `llm_dart`

## Related Docs

- Root package overview: `../../README.md`
- Flutter architecture notes:
  `../../docs/workstreams/2026-03-architecture-refactor/04-flutter-chat-integration.md`
- Migration guide:
  `../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md`
