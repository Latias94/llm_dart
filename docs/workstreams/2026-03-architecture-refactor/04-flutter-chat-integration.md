# Flutter Chat Integration

## Goal

The new Flutter integration surface must solve several problems that are visible in the current examples:

- callers hold providers directly, which tightly couples UI code to model implementations
- messages are still centered around `ChatMessage.content`, which cannot naturally represent reasoning, tools, sources, or files
- streamed rendering requires application code to reconstruct `TextDeltaEvent` behavior manually
- there is no real session layer, transport layer, or persistence boundary

For that reason, Flutter support cannot stay at the level of a conceptual README example. It needs a real, reusable UI-facing abstraction layer.

## 1. What Flutter Chat Applications Actually Need

The UI layer of a chat application usually needs:

- current message list
- current send state
- incremental streamed updates
- stop generation
- regenerate
- tool execution state
- cited sources
- attachments
- local persistence
- both direct-model mode and remote-HTTP-backend mode

If the lower layer only exposes `Future<ChatResponse>` and `Stream<TextDeltaEvent>`, every application ends up re-implementing the same state logic.

## 2. Recommended New Chat Layer

## 1. `ChatUiMessage`

```dart
final class ChatUiMessage {
  final String id;
  final ChatUiRole role;
  final List<ChatUiPart> parts;
  final Map<String, Object?> metadata;
}
```

Suggested roles:

- `system`
- `user`
- `assistant`

Suggested parts:

- `TextUiPart`
- `ReasoningUiPart`
- `ToolUiPart`
- `SourceUiPart`
- `FileUiPart`
- `DataUiPart<T>`
- `CustomUiPart`
- `StepBoundaryUiPart`

## 2. `ToolUiPart`

Tool rendering must represent more than “there was a tool call”. It should represent a state machine:

- `inputStreaming`
- `inputAvailable`
- `approvalRequested`
- `approvalResponded`
- `outputAvailable`
- `outputError`
- `outputDenied`

That directly determines whether the Flutter UI can naturally support:

- argument display
- approval interaction
- output injection
- error presentation

It also needs richer fields than a minimal tool-call record:

- `inputText` for partial streamed arguments before they become valid structured input
- `approval` for provider-executed approval flows
- `providerExecuted`, `isDynamic`, `preliminary`, and `title`
- separate call/result provider metadata so provider-native detail is not lost during the state transition

## 3. `ChatState`

```dart
final class ChatState {
  final String chatId;
  final List<ChatUiMessage> messages;
  final ChatStatus status;
  final Object? error;
}
```

Suggested states:

- `ready`
- `submitting`
- `streaming`
- `error`

## 4. `ChatUiAccumulator`

The pure Dart core layer should provide a reusable projector from `TextStreamEvent` to `ChatUiMessage`.

Recommended surface:

```dart
final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

await for (final event in streamText(model: model, prompt: prompt)) {
  final message = accumulator.apply(event);
  render(message);
}
```

Or as a stream helper:

```dart
final messages = projectChatUiMessageStream(
  streamText(model: model, prompt: prompt),
  messageId: 'assistant-1',
);
```

This is important because Flutter applications should not have to re-implement:

- active text-part tracking
- active reasoning-part tracking
- partial tool-input accumulation
- tool-part state transitions
- response metadata updates
- source/custom/file insertion
- optional raw diagnostic capture

The projector should stay in `llm_dart_core`, not in `llm_dart_flutter`, because the state machine is architecture-level behavior, not widget behavior.

## 3. Recommended Session API

## 1. `ChatSession`

```dart
abstract interface class ChatSession {
  ChatState get state;

  Stream<ChatState> get states;

  Future<void> sendMessage(ChatInput input, {ChatRequestOptions? options});

  Future<void> regenerate({String? messageId, ChatRequestOptions? options});

  Future<void> addToolOutput(ToolOutputUpdate update);

  Future<void> respondToolApproval(ToolApprovalResponse response);

  Future<void> resume();

  Future<void> stop();

  Future<void> clearError();

  Future<void> dispose();
}
```

Key points:

- `ChatSession` should not expose providers directly
- UI operations should revolve around sessions, not models
- tool-result injection and approval handling are session concerns, not provider concerns

Current implementation direction:

- phase 1 should already provide a baseline `DefaultChatSession` for direct `LanguageModel` streaming
- the baseline session may initially support send, stop, clear-error, and simple regenerate before full tool loop support lands
- tool output injection, approval response, and reconnect can remain explicitly unsupported until the transport and tool orchestration contracts are frozen

## 2. `ChatTransport`

Borrow the idea from the Vercel AI SDK, but do not copy its hooks-centered design.

```dart
abstract interface class ChatTransport {
  Future<Stream<ChatStreamChunk>> sendMessages(ChatTransportRequest request);

  Future<Stream<ChatStreamChunk>?> reconnect(String chatId);
}
```

Two implementations should exist early:

### `DirectChatTransport`

Use cases:

- Flutter directly calling a local `LanguageModel`
- suitable for CLI tools, desktop apps, and local prototypes

### `HttpChatTransport`

Use cases:

- Flutter apps connecting to a backend
- server-side API key management, logging, caching, and auditing

This layer matters because mobile and production deployments often should not call cloud providers directly.

## 4. Do Not Pull Flutter Dependencies Back into Core

`llm_dart_flutter` should stay separate from `llm_dart_core` for the following reasons:

- `core` remains pure Dart
- the Flutter package can safely depend on `foundation`
- the package can offer `ValueNotifier`, `ChangeNotifier`, or `Listenable` adapters
- it does not force a specific framework such as BLoC, Riverpod, or Provider

## 5. Recommended Public Objects for Flutter

## 1. Pure Dart Layer

- `ChatSession`
- `ChatTransport`
- `ChatState`
- `ChatUiMessage`
- `ChatUiPart`
- `ChatUiAccumulator`

## 2. Flutter Convenience Layer

Optional, but useful:

- `ChatController extends ValueNotifier<ChatState>`
- `ChatMessageMapper`
- `ChatPersistenceAdapter`

## 6. Message Metadata Conventions

`ChatUiMessage.metadata` should reserve a small common set of keys for cross-provider state that is not naturally a message part:

- warnings
- response ID, timestamp, model ID, and response provider metadata
- finish reason, usage, and finish provider metadata
- streamed errors
- optional raw chunks for diagnostic mode only

These keys should be documented and stable enough for Flutter session and persistence layers, but they should remain a small projection surface rather than growing into another provider-specific dumping ground.

## 7. Attachment Design

The core message model should not depend on `dart:io File`. Flutter integration should use reference-style attachment objects instead:

```dart
sealed class AttachmentRef {}

final class BytesAttachmentRef extends AttachmentRef { ... }
final class UriAttachmentRef extends AttachmentRef { ... }
final class AssetAttachmentRef extends AttachmentRef { ... }
```

The prompt layer can then map these references into:

- image parts
- file parts
- audio parts

This keeps the architecture:

- portable across Flutter mobile, desktop, and web
- independent of platform-specific file abstractions

## 8. Recommended Flutter Usage Style

```dart
final model = AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

final session = DefaultChatSession(
  transport: DirectChatTransport(model: model),
);

await session.sendMessage(
  ChatInput.text('Explain when to use isolates in Flutter'),
);
```

Or in backend mode:

```dart
final session = DefaultChatSession(
  transport: HttpChatTransport(
    endpoint: Uri.parse('https://api.example.com/chat'),
  ),
);
```

## 9. Why `parts` Works Better Than the Current `ChatMessage.content`

Problems with the current model:

- text, reasoning, tools, and sources are mixed between string fields and auxiliary data
- UI updates require too much manual state stitching
- tool output injection has no natural render path
- multi-step tool loops need explicit step boundaries instead of implicit ad hoc conventions

Benefits of a `parts` model:

- a single message can contain multiple renderable elements
- streamed updates can target parts directly
- list UIs, rich-message UIs, and tool-card UIs all become more natural
- serialization and local persistence become more stable

## 10. Things That Should Be Delayed

The first phase should not attempt to build:

- a widget library with ready-made Flutter chat UI widgets
- a session layer tightly bound to Riverpod or BLoC
- a full chat database solution
- multi-tenant or multi-session synchronization layers

The message model, session model, and transport layer need to be correct first. Reusable UI components can only be stable after that.
