import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_chat/src/http_chat_transport_server_projection.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportServerProjection', () {
    test('injects legacy start only once for v1 streams', () async {
      const projection = HttpChatTransportServerProjection();

      final chunks = await projection
          .encodeUiChunkStream(
            streamProtocol: HttpChatTransportStreamProtocol.eventStreamV1,
            requestId: 'req-1',
            defaultMessageId: 'default-message',
            resumeToken: 'resume-1',
            stream: Stream.fromIterable([
              const ChatUiEventChunk(TextStartEvent(id: 'text-1')),
              const ChatUiEventChunk(TextEndEvent(id: 'text-1')),
            ]),
          )
          .toList();

      final startChunks = chunks.whereType<HttpChatTransportStartChunk>();
      expect(startChunks, hasLength(1));
      expect(startChunks.single.requestId, 'req-1');
      expect(startChunks.single.messageId, 'default-message');
      expect(startChunks.single.resumeToken, 'resume-1');
      expect(chunks.whereType<HttpChatTransportEventChunk>(), hasLength(2));
      expect(chunks.last, isA<HttpChatTransportFinishChunk>());
    });

    test('projects v2 message metadata when no message id is available',
        () async {
      const projection = HttpChatTransportServerProjection();

      final chunks = await projection
          .encodeUiChunkStream(
            stream: Stream.fromIterable([
              ChatUiMessageStartChunk(
                metadata: const {
                  'phase': 'streaming',
                },
              ),
              const ChatUiEventChunk(TextStartEvent(id: 'text-1')),
            ]),
          )
          .toList();

      final metadata = chunks[0] as HttpChatTransportMessageMetadataChunk;
      expect(metadata.metadata['phase'], 'streaming');
      expect(chunks[1], isA<HttpChatTransportEventChunk>());
      expect(chunks.last, isA<HttpChatTransportFinishChunk>());
    });
  });
}
