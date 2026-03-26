import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('DirectChatTransport', () {
    test('maps chat transport requests to language model requests', () async {
      GenerateTextRequest? capturedRequest;

      final transport = DirectChatTransport(
        model: _FakeLanguageModel(
          onStream: (request) {
            capturedRequest = request;
            return const Stream<TextStreamEvent>.empty();
          },
        ),
      );

      await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: const ChatRequestOptions(
                generateOptions: GenerateTextOptions(
                  temperature: 0.2,
                ),
              ),
            ),
          )
          .drain<void>();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.prompt.single, isA<UserPromptMessage>());
      expect(capturedRequest!.options.temperature, 0.2);
    });
  });

  group('DefaultChatSession', () {
    test('appends user and assistant messages and returns to ready state',
        () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const TextStartEvent(id: 'text-1'),
            const TextDeltaEvent(id: 'text-1', delta: 'Hello'),
            const TextEndEvent(id: 'text-1'),
            const FinishEvent(finishReason: FinishReason.stop),
          ]),
        ),
      );

      final emittedStates = <ChatState>[];
      final subscription = session.states.listen(emittedStates.add);

      await session.sendMessage(ChatInput.text('Hi'));

      expect(session.state.status, ChatStatus.ready);
      expect(session.state.error, isNull);
      expect(session.state.messages, hasLength(2));
      expect(session.state.messages.first.role, ChatUiRole.user);
      expect(
        session.state.messages.first.parts.whereType<TextUiPart>().single.text,
        'Hi',
      );
      expect(session.state.messages.last.role, ChatUiRole.assistant);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Hello',
      );
      expect(
        emittedStates.map((state) => state.status),
        containsAllInOrder([
          ChatStatus.submitting,
          ChatStatus.streaming,
          ChatStatus.ready,
        ]),
      );

      await subscription.cancel();
      await session.dispose();
    });

    test('stop marks the active assistant turn as aborted', () async {
      final controller = StreamController<TextStreamEvent>();
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => controller.stream,
        ),
      );

      final sendFuture = session.sendMessage(ChatInput.text('Hi'));
      await Future<void>.delayed(Duration.zero);

      controller.add(StartEvent());
      controller.add(const TextStartEvent(id: 'text-1'));
      controller.add(const TextDeltaEvent(id: 'text-1', delta: 'Partial'));
      await Future<void>.delayed(Duration.zero);

      await session.stop();
      await sendFuture;
      await controller.close();

      expect(session.state.status, ChatStatus.ready);
      expect(session.state.messages, hasLength(2));
      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.metadata[ChatUiMetadataKeys.finishReason],
        FinishReason.aborted,
      );
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'Partial',
      );

      await session.dispose();
    });

    test('regenerate replaces the latest assistant message', () async {
      var invocation = 0;
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            invocation += 1;
            return Stream<TextStreamEvent>.fromIterable([
              StartEvent(),
              const TextStartEvent(id: 'text-1'),
              TextDeltaEvent(
                id: 'text-1',
                delta: invocation == 1 ? 'First' : 'Second',
              ),
              const TextEndEvent(id: 'text-1'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));
      await session.regenerate();

      expect(session.state.messages, hasLength(2));
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Second',
      );

      await session.dispose();
    });

    test('transitions to error state when the stream emits ErrorEvent',
        () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const ErrorEvent('provider failed'),
          ]),
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));

      expect(session.state.status, ChatStatus.error);
      expect(session.state.error, 'provider failed');
      expect(session.state.messages, hasLength(2));

      await session.clearError();
      expect(session.state.status, ChatStatus.ready);
      expect(session.state.error, isNull);

      await session.dispose();
    });
  });
}

final class _FakeChatTransport implements ChatTransport {
  final Stream<TextStreamEvent> Function(ChatTransportRequest request)
      onSendMessages;

  const _FakeChatTransport({
    required this.onSendMessages,
  });

  @override
  Stream<TextStreamEvent>? reconnect(String chatId) => null;

  @override
  Stream<TextStreamEvent> sendMessages(ChatTransportRequest request) {
    return onSendMessages(request);
  }
}

final class _FakeLanguageModel implements LanguageModel {
  final Stream<TextStreamEvent> Function(GenerateTextRequest request) onStream;

  const _FakeLanguageModel({
    required this.onStream,
  });

  @override
  String get modelId => 'fake-model';

  @override
  String get providerId => 'fake';

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) {
    throw UnimplementedError();
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) {
    return onStream(request);
  }
}
