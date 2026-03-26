import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportRequestJsonCodec', () {
    test('round-trips prompt, generate options, and metadata', () {
      const codec = HttpChatTransportRequestJsonCodec();
      final encoded = codec.encodeRequest(
        HttpChatTransportRequestPayload(
          chatId: 'chat-1',
          prompt: [
            UserPromptMessage.text('Hello'),
          ],
          generateOptions: const GenerateTextOptions(
            maxOutputTokens: 256,
            temperature: 0.2,
            stopSequences: ['DONE'],
            topP: 0.9,
            topK: 40,
          ),
          metadata: const {
            'clientRequestId': 'req-1',
          },
        ),
      );

      expect(encoded['kind'], HttpChatTransportRequestJsonCodec.envelopeKind);

      final decoded = codec.decodeRequest(encoded);
      expect(decoded.chatId, 'chat-1');
      expect(decoded.prompt.single, isA<UserPromptMessage>());
      expect(decoded.generateOptions.maxOutputTokens, 256);
      expect(decoded.generateOptions.temperature, 0.2);
      expect(decoded.generateOptions.stopSequences, ['DONE']);
      expect(decoded.generateOptions.topP, 0.9);
      expect(decoded.generateOptions.topK, 40);
      expect(decoded.metadata, {
        'clientRequestId': 'req-1',
      });
    });
  });

  group('HttpChatTransportChunkJsonCodec', () {
    test('round-trips transport chunks and text stream events', () {
      const codec = HttpChatTransportChunkJsonCodec();
      final chunks = [
        const HttpChatTransportStartChunk(
          requestId: 'req-1',
          messageId: 'assistant-1',
          resumeToken: 'resume-1',
        ),
        const HttpChatTransportEventChunk(
          TextDeltaEvent(
            id: 'text-1',
            delta: 'Hello',
            providerMetadata: ProviderMetadata({
              'openai': {
                'itemId': 'msg_1',
              },
            }),
          ),
        ),
        const HttpChatTransportCheckpointChunk(
          resumeToken: 'resume-2',
          cursor: 'cursor-2',
        ),
        const HttpChatTransportFinishChunk(),
        const HttpChatTransportAbortChunk(
          reason: 'cancelled',
        ),
        const HttpChatTransportErrorChunk(
          message: 'backend failed',
          code: 'transport_error',
          details: {
            'retryable': false,
          },
        ),
        const HttpChatTransportKeepAliveChunk(),
      ];

      final decoded = chunks
          .map(codec.encodeChunk)
          .map<Object?>((chunk) => chunk)
          .map(codec.decodeChunk)
          .toList(growable: false);

      expect(decoded[0], isA<HttpChatTransportStartChunk>());
      expect(
        (decoded[0] as HttpChatTransportStartChunk).resumeToken,
        'resume-1',
      );

      final eventChunk = decoded[1] as HttpChatTransportEventChunk;
      expect(eventChunk.event, isA<TextDeltaEvent>());
      expect((eventChunk.event as TextDeltaEvent).delta, 'Hello');

      final checkpoint = decoded[2] as HttpChatTransportCheckpointChunk;
      expect(checkpoint.cursor, 'cursor-2');

      expect(decoded[3], isA<HttpChatTransportFinishChunk>());
      expect((decoded[4] as HttpChatTransportAbortChunk).reason, 'cancelled');

      final error = decoded[5] as HttpChatTransportErrorChunk;
      expect(error.code, 'transport_error');
      expect(error.details, {
        'retryable': false,
      });

      expect(decoded[6], isA<HttpChatTransportKeepAliveChunk>());
    });
  });
}
