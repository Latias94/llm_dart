import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiStreamError', () {
    test('is thrown for text deltas without a matching text start', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      expect(
        () => accumulator.apply(
          const TextDeltaEvent(
            id: 'missing-text',
            delta: 'Hello',
          ),
        ),
        throwsA(
          isA<ChatUiStreamError>()
              .having((error) => error.chunkType, 'chunkType', 'text-delta')
              .having((error) => error.chunkId, 'chunkId', 'missing-text')
              .having(
                (error) => error.message,
                'message',
                contains('Ensure a "text-start" event is applied first.'),
              ),
        ),
      );
    });

    test('is thrown for tool input deltas without a matching input start', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      expect(
        () => accumulator.apply(
          const ToolInputDeltaEvent(
            toolCallId: 'missing-tool',
            delta: '{"city"',
          ),
        ),
        throwsA(
          isA<ChatUiStreamError>()
              .having(
                (error) => error.chunkType,
                'chunkType',
                'tool-input-update',
              )
              .having((error) => error.chunkId, 'chunkId', 'missing-tool'),
        ),
      );
    });

    test('converts to a stream ModelError with chunk diagnostics', () {
      const error = ChatUiStreamError(
        chunkType: 'reasoning-end',
        chunkId: 'reasoning-1',
        message: 'bad stream',
      );

      final modelError = error.toModelError();

      expect(modelError.kind, ModelErrorKind.stream);
      expect(modelError.code, 'chat-ui-stream');
      expect(modelError.message, 'bad stream');
      expect(modelError.details, {
        'chunkType': 'reasoning-end',
        'chunkId': 'reasoning-1',
      });
      expect(modelError.originalType, 'ChatUiStreamError');
    });

    test('fails readChatUiStream result with the typed stream error', () async {
      final result = readChatUiStream(
        messageId: 'assistant-1',
        chunks: Stream<ChatUiStreamChunk>.fromIterable([
          const ChatUiEventChunk(
            TextEndEvent(id: 'missing-text'),
          ),
        ]),
      );

      await expectLater(
        result.result,
        throwsA(
          isA<ChatUiStreamError>()
              .having((error) => error.chunkType, 'chunkType', 'text-end')
              .having((error) => error.chunkId, 'chunkId', 'missing-text'),
        ),
      );
    });
  });
}
