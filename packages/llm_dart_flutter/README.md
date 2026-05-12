# llm_dart_flutter

Flutter adapter layer for the shared `llm_dart_chat` runtime.

This package re-exports the pure Dart chat runtime and adds Flutter-specific
adapters on top of it. It does not add another provider abstraction.

The package is intentionally small:

- no prebuilt chat widgets
- no framework lock-in
- no storage backend
- no provider-specific API flattening

Recommended adoption order:

- start with `DirectChatTransport` plus a stable `LanguageModel` for trusted
  local prototypes or internal tools
- prefer `HttpChatTransport` for production apps when keys, routing, caching,
  approvals, or compliance rules belong on the backend
- keep persistence application-owned through `ChatPersistenceAdapter`
- add provider-specific mappers or custom-part helpers only when the UI truly
  needs provider-owned inspection

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

The shared `ChatMessageMapper` now lives in `llm_dart_ai` and is re-exported
through both `llm_dart_chat` and `llm_dart_flutter`.

What stays outside both packages:

- provider configuration
- typed provider options
- prompt and result model definitions
- raw transport implementation details that belong to providers or servers

## Layer Model

The recommended architecture is:

1. `llm_dart` selects and configures a provider model.
2. `llm_dart_provider` defines prompt, stream, result, provider metadata, and
   provider option semantics.
3. `llm_dart_ai` defines shared UI message semantics and
   `ChatMessageMapper`.
4. `llm_dart_chat` owns provider-agnostic session state, transport adaptation,
   persistence boundaries, and chat runtime orchestration.
5. `llm_dart_flutter` adds widget-friendly control surfaces such as
   `ChatController`.

This keeps the unified layer focused on stable model semantics while still
leaving room for provider-owned features through:

- `CallOptions.providerOptions`
- `ProviderMetadata`
- `CustomUiPart`
- backend-owned HTTP chunk metadata when needed

## Direct Model Example

Use this path for trusted-device prototypes or internal tools where the client
is allowed to own direct model access.

Use `DirectChatTransport` when Flutter can call the model directly.

```dart
import 'package:llm_dart/openai.dart' as openai;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

Future<void> main() async {
  final controller = ChatController(
    session: DefaultChatSession(
      transport: DirectChatTransport(
        model: openai.openai(
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

    final shared = const ChatMessageMapper().map(state.messages.last);
    print('status=${state.status}');
    print('assistantText=${shared.text}');
    print('providerMetadata=${shared.responseProviderMetadata != null}');
  });

  await controller.sendMessage(
    ChatInput.text('Write a short haiku about Flutter widgets.'),
  );

  await controller.close();
}
```

## Remote Backend Example

Use `HttpChatTransport` when API keys, auditing, caching, tool execution, or
compliance concerns require a backend. This is the preferred production shape
for most mobile or distributed Flutter applications.

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

For a fuller controller-level example that keeps provider-specific invocation
settings backend-owned, see:

- `example/flutter_http_backend_integration.dart`

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

For a runnable pure-Dart backend-hint example that uses the same runtime layer
Flutter builds on, see
`../llm_dart_chat/example/http_backend_hint_mapping.dart`.

For the Flutter-controller variant of the same pattern, see
`example/flutter_http_backend_integration.dart`.

For a minimal widget-level `MaterialApp` that uses the same backend-owned
routing pattern, see `example/flutter_material_chat_demo.dart`.
Run it from the package root with:

```bash
flutter run -t example/flutter_material_chat_demo.dart
```

For a widget-level reconnect recovery example that uses `HttpChatTransport`
plus `resume()`, see `example/flutter_http_reconnect_demo.dart`.

If your backend is also Dart, prefer building the SSE response in
`package:llm_dart_transport` rather than `llm_dart_flutter`:

```dart
import 'package:llm_dart_transport/llm_dart_transport.dart';

final adapter = HttpChatTransportServerAdapter();

final body = adapter.encodeEventSseStream(
  eventStream: model.doStream(request),
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

For a widget-level example that saves and restores paused tool state in
`awaitingApproval` and `awaitingTool`, see
`example/flutter_tool_approval_demo.dart`.

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

Use `ChatMessageMapper` as the shared baseline, then keep provider-specific
inspection in app code or provider custom-part helpers outside the Flutter
adapter.

Provider-owned custom parts can stay provider-owned until the UI decides how to
render them. For example, Google server-side tool replay can be summarized from
provider content parts or stream events before UI projection without widening
`llm_dart_flutter`:

```dart
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

void renderGoogleCustomParts(List<ContentPart> parts) {
  final summaries = GoogleCustomPartSummary.parseContentParts(parts);

  for (final summary in summaries) {
    print(summary.title);
    print(summary.subtitle);
    print(summary.previewText);
  }
}
```

If the UI also needs OpenAI-specific metadata from common parts such as
response/item IDs, tool/source details, or logprobs, inspect the
provider-metadata namespace on the shared mapped message or individual parts:

```dart
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

void renderOpenAIMessage(ChatUiMessage message) {
  final shared = const ChatMessageMapper().map(message);

  print(shared.text);
  print(shared.responseProviderMetadata?.namespace('openai'));
}
```

If the UI instead needs Google-specific metadata from common parts such as
thought signatures, `responsePart`, or Google file IDs, keep the same shared
projection and read the Google metadata namespace in app UI code:

```dart
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

void renderGoogleMessage(ChatUiMessage message) {
  final shared = const ChatMessageMapper().map(message);

  print(shared.text);
  print(shared.responseProviderMetadata?.namespace('google'));
}
```

This layered composition is the intended extension model:

- shared mapper for stable cross-provider rendering
- app-owned inspection for provider metadata that appears on shared UI parts
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

Denied approval reasons are preserved in shared session state and snapshots as
explicit denied tool output. A provider package may still replay only the fields
its native approval protocol supports.

For a widget-level example that demonstrates HTTP stream failure, error-state
rendering, and reconnect recovery through `resume()`, see
`example/flutter_http_reconnect_demo.dart`.

For a widget-level example that walks the UI through
`awaitingApproval -> awaitingTool -> ready`, and also demonstrates paused-state
snapshot restore, see
`example/flutter_tool_approval_demo.dart`.

## Capability-Gated UI Example

Use capability profiles to gate shared controls such as attachments,
structured-output toggles, reasoning inspectors, and source panels.

```dart
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

final profile = describeOpenAIChatModel('gpt-5.4');

final canAttachImages = profile.supports(
  ModelCapabilityFeatureIds.languageImageInput,
);
final canShowReasoning = profile.supports(
  ModelCapabilityFeatureIds.languageReasoningOutput,
);
final route = profile.providerFeature('openai', 'api.route')?.detail;
```

This is the intended layering:

- use shared feature IDs for uniform Flutter affordances
- use provider feature descriptors for provider-aware panels and badges
- keep capability checks descriptive, not as hard runtime guarantees

For `llm_dart_ollama` and `llm_dart_elevenlabs`, also look at descriptor
confidence before turning a model answer into strong UI copy. Ollama
vision/reasoning hints may be `inferred` from the local model family.

```dart
import 'package:llm_dart_ollama/llm_dart_ollama.dart';

final profile = describeOllamaChatModel('llama3.2-vision');
final imageInput = profile.sharedFeature(
  ModelCapabilityFeatureIds.languageImageInput,
);

final canAttachImages = imageInput != null;
final showInferenceBadge =
    imageInput?.confidence == CapabilityConfidence.inferred;
```

Use this pattern when the Flutter UI wants to say "likely supported by this
model family" without pretending the local Ollama install is a hosted contract.

For a runnable Material demo, see
`example/flutter_capability_gated_controls.dart`.

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

Use `ToolExecutionResult.toolOutput(...)` when a local tool needs to return an
explicit `TextToolOutput`, `JsonToolOutput`, `ExecutionDeniedToolOutput`, or
`ContentToolOutput`. The `output` and `error` constructors remain convenient
shortcuts for simple JSON-like results.

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
shared schema validation layer in `llm_dart_provider`.

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
- Keep Flutter dependencies out of `llm_dart_provider`.
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
