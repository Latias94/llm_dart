# llm_dart_flutter

Flutter adapter layer for the shared `llm_dart_chat` runtime.

This package re-exports the pure Dart chat runtime and adds Flutter-specific
adapters on top of it. It does not add another provider abstraction.

The package is intentionally small:

- no prebuilt chat widgets
- no framework lock-in
- no storage backend
- no provider-specific API flattening

## What This Package Adds

`llm_dart_flutter` directly owns only the Flutter-facing adapter layer:

- `ChatController`
  - `ValueNotifier<ChatState>` wrapper for widget integration
- `ChatPersistenceAdapter`
  - thin controller-aware wrapper above the shared snapshot persistence helper
- re-export of `llm_dart_chat`
  - so Flutter apps can import one package and still use the shared runtime

The reusable runtime itself lives in `llm_dart_chat` and owns:

- `ChatTransport`
- `DirectChatTransport`
- `HttpChatTransport`
- `ChatSession`
- `DefaultChatSession`
- snapshot and session persistence codecs

The shared `ChatMessageMapper` now lives in `llm_dart_core` and is re-exported
through both `llm_dart_chat` and `llm_dart_flutter`.

What stays outside both packages:

- provider configuration
- typed provider options
- prompt and result model definitions
- raw transport implementation details that belong to providers or servers

## Layer Model

The recommended architecture is:

1. `llm_dart` selects and configures a provider model.
2. `llm_dart_core` defines prompt, stream, result, UI message semantics, and
   the shared `ChatMessageMapper`.
3. `llm_dart_chat` owns provider-agnostic session state, transport adaptation,
   persistence boundaries, and chat runtime orchestration.
4. `llm_dart_flutter` adds widget-friendly control surfaces such as
   `ChatController`.

This keeps the unified layer focused on stable model semantics while still
leaving room for provider-owned features through:

- `CallOptions.providerOptions`
- `ProviderMetadata`
- `CustomUiPart`
- backend-owned HTTP chunk metadata when needed

## Direct Model Example

Use `DirectChatTransport` when Flutter can call the model directly.

```dart
import 'package:llm_dart/openai.dart' as openai;
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

    final mapped =
        const openai.OpenAIMessageMapper().mapComposed(state.messages.last);
    final shared = mapped.shared;
    final provider = mapped.provider;
    print('status=${state.status}');
    print('assistantText=${shared.text}');
    print('openaiMetadata=${provider.hasOpenAIMetadata}');
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

Use `metadata` plus `prepareSendMessagesRequest` /
`prepareReconnectRequest` when the client needs to send app-owned JSON hints to
the backend. If the caller must own typed provider invocation options directly,
prefer `DirectChatTransport` instead of widening the generic HTTP transport
envelope.

If your backend is also Dart, prefer building the SSE response in
`package:llm_dart_transport` rather than `llm_dart_flutter`:

```dart
import 'package:llm_dart_transport/llm_dart_transport.dart';

final adapter = HttpChatTransportServerAdapter();

final body = adapter.encodeEventSseStream(
  eventStream: model.stream(request),
  requestId: 'req-1',
  messageId: 'assistant-1',
  resumeToken: 'resume-1',
  messageMetadata: const {
    'serverOwned': true,
  },
);
```

The request/chunk codecs are transport-owned now and are re-exported here only
for client-side compatibility.

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

Use `ChatMessageMapper` as the shared baseline, then add a provider-owned mapper
only when the UI needs provider-specific inspection.

Provider-owned custom parts can stay provider-owned all the way to the UI. For
example, Google server-side tool replay can be rendered through the Google
package without widening `llm_dart_flutter`:

```dart
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_google/llm_dart_google.dart';

void renderGoogleCustomParts(ChatUiMessage message) {
  final summaries = GoogleCustomPartSummary.parseUiParts(message.parts);

  for (final summary in summaries) {
    print(summary.title);
    print(summary.subtitle);
    print(summary.previewText);
  }
}
```

If the UI also needs OpenAI-specific metadata from common parts such as
response/item IDs, tool/source details, or logprobs, use the provider-owned
composed mapper helper:

```dart
import 'package:llm_dart/openai.dart' as openai;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

void renderOpenAIMessage(ChatUiMessage message) {
  final mapped = const openai.OpenAIMessageMapper().mapComposed(message);
  final shared = mapped.shared;
  final provider = mapped.provider;

  print(shared.text);
  print(provider.hasOpenAIMetadata);
  print(provider.hasLogprobs);

  for (final detail in provider.partDetails) {
    print('${detail.type}: ${detail.label}');
    print(detail.itemId);
    print(detail.toolCallId);
    print(detail.sourceId);
  }
}
```

If the UI instead needs Google-specific metadata from common parts such as
thought signatures, `responsePart`, or Google file IDs, use the Google mapper
the same way:

```dart
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

void renderGoogleMessage(ChatUiMessage message) {
  final mapped = const google.GoogleMessageMapper().mapComposed(message);
  final shared = mapped.shared;
  final provider = mapped.provider;

  print(shared.text);
  print(provider.hasGoogleMetadata);
  print(provider.hasThoughtSignatures);

  for (final detail in provider.partDetails) {
    print('${detail.type}: ${detail.label}');
    print(detail.thoughtSignature);
    print(detail.responsePart);
    print(detail.sourceId);
    print(detail.chunkType);
  }
}
```

This layered composition is the intended extension model:

- shared mapper for stable cross-provider rendering
- provider mapper for provider-owned metadata inspection
- composed provider helper when the UI needs both layers together
- provider custom-part helpers for provider-owned replay payload rendering

## Tool and Approval Flows

`DefaultChatSession` supports the baseline interactive loop needed by chat UIs:

- send user messages
- stream assistant messages
- pause on client-executed tools
- inject tool output with `addToolOutput`
- optionally auto-resolve client-executed tools with `onToolCall`
- optionally use `ToolExecutionRegistry` for name-based local tool dispatch
- pause on approval requests
- respond with `respondToolApproval`
- wait for the current assistant step to finish collecting local tool output and approval responses before continuing the next turn
- stop active generation
- resume reconnectable HTTP sessions after transport errors

Provider-executed tool behavior remains provider-owned. The session layer only
models stable tool and approval state transitions that a Flutter UI needs to
render.

## Optional Local Tool Callback

`DefaultChatSession` can also auto-run local client-side tools through
`onToolCall`.

```dart
final session = DefaultChatSession(
  transport: DirectChatTransport(model: model),
  onToolCall: (request) async {
    if (request.toolName != 'weather') {
      return null;
    }

    return const ToolExecutionResult.output({
      'temperature': 24,
      'unit': 'celsius',
    });
  },
);
```

Important notes:

- `onToolCall` only applies to client-executed tools
- approval still gates local execution when a tool first enters
  `approvalRequested`
- callback failures are mapped into tool error output, not generic session
  errors

## Tool Execution Registry

Use `ToolExecutionRegistry` when simple tool-name dispatch is enough.

```dart
final session = DefaultChatSession(
  transport: DirectChatTransport(model: model),
  toolExecutionRegistry: ToolExecutionRegistry(
    handlers: {
      'weather': (request) async => const ToolExecutionResult.output({
        'temperature': 24,
        'unit': 'celsius',
      }),
      'calendar': (request) async => const ToolExecutionResult.output({
        'events': ['Standup'],
      }),
    },
  ),
);
```

When a tool expects a JSON object payload, prefer `withJsonHandler` to keep the
decode step close to the handler:

```dart
final registry = ToolExecutionRegistry().withJsonHandler<String>(
  'weather',
  decode: (json) => json['location'] as String,
  handle: (request, location) async => ToolExecutionResult.output({
    'location': location,
    'temperature': 24,
  }),
);
```

By default:

- non-object tool input becomes a tool error result
- decode failures become a tool error result
- these failures stay inside the local tool flow instead of moving the session
  into a generic error state

This is a Flutter/session convenience for local tool execution. It is not a
shared schema validation layer in `llm_dart_core`.

Use `onToolCall` directly when:

- dispatch depends on more than `toolName`
- you want custom fallback logic
- you need to enrich UI state before returning the tool output

## Design Rules

- Unify stable model semantics, not every provider surface.
- Keep provider-specific features in typed provider options, metadata, or
  custom parts.
- Keep the reusable chat runtime in `llm_dart_chat`.
- Keep storage application-owned.
- Keep Flutter dependencies out of `llm_dart_core`.
- Keep Flutter-only adapters in `llm_dart_flutter`.
- Keep this package framework-neutral beyond Flutter `foundation`.

## Non-Goals

This package does not try to provide:

- a widget library
- a local database
- a BLoC, Riverpod, or Provider integration layer
- a backend implementation
- a new provider abstraction on top of `llm_dart`
- the framework-neutral chat runtime itself

## Related Docs

- Pure Dart runtime guide:
  `../llm_dart_chat/README.md`
- Root package overview: `../../README.md`
- Flutter architecture notes:
  `../../docs/workstreams/2026-03-architecture-refactor/04-flutter-chat-integration.md`
- Migration guide:
  `../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md`
