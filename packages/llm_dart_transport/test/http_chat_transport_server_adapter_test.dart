import 'package:llm_dart_core/model.dart' show FinishReason;
import 'package:llm_dart_core/ui.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportServerAdapter', () {
    test('encodes text stream events as v2 SSE frames', () async {
      const adapter = HttpChatTransportServerAdapter();
      const parser = SseJsonChunkParser();
      const chunkCodec = HttpChatTransportChunkJsonCodec();

      final payloads = await parser
          .parse(
            adapter.encodeEventSseStream(
              eventStream: Stream.fromIterable([
                const TextStartEvent(id: 'text-1'),
                const TextDeltaEvent(
                  id: 'text-1',
                  delta: 'Hello',
                ),
                const TextEndEvent(id: 'text-1'),
                const FinishEvent(
                  finishReason: FinishReason.stop,
                ),
              ]),
              requestId: 'req-1',
              messageId: 'assistant-1',
              resumeToken: 'resume-1',
              messageMetadata: const {
                'serverOwned': true,
              },
              finalMessageMetadata: const {
                'persisted': true,
              },
              includeDoneFrame: true,
            ),
          )
          .toList();

      final chunks = payloads
          .map<Object?>((payload) => payload)
          .map(chunkCodec.decodeChunk)
          .toList(growable: false);

      expect(chunks[0], isA<HttpChatTransportTransportStartChunk>());
      expect(
        (chunks[0] as HttpChatTransportTransportStartChunk).resumeToken,
        'resume-1',
      );

      final messageStart = chunks[1] as HttpChatTransportMessageStartChunk;
      expect(messageStart.messageId, 'assistant-1');
      expect(messageStart.metadata['serverOwned'], isTrue);

      expect(chunks[2], isA<HttpChatTransportEventChunk>());
      expect((chunks[2] as HttpChatTransportEventChunk).event,
          isA<TextStartEvent>());
      expect(
        ((chunks[3] as HttpChatTransportEventChunk).event as TextDeltaEvent)
            .delta,
        'Hello',
      );
      expect((chunks[4] as HttpChatTransportEventChunk).event,
          isA<TextEndEvent>());
      expect(
          (chunks[5] as HttpChatTransportEventChunk).event, isA<FinishEvent>());

      final messageFinish = chunks[6] as HttpChatTransportMessageFinishChunk;
      expect(messageFinish.metadata['persisted'], isTrue);
      expect(chunks[7], isA<HttpChatTransportFinishChunk>());
    });

    test('downgrades message metadata to v1-compatible chunks', () async {
      const adapter = HttpChatTransportServerAdapter();
      const parser = SseJsonChunkParser();
      const chunkCodec = HttpChatTransportChunkJsonCodec();

      final payloads = await parser
          .parse(
            adapter.encodeEventSseStream(
              eventStream: Stream.fromIterable([
                const TextStartEvent(id: 'text-1'),
                const TextDeltaEvent(
                  id: 'text-1',
                  delta: 'Hello',
                ),
                const FinishEvent(
                  finishReason: FinishReason.stop,
                ),
              ]),
              streamProtocol: HttpChatTransportStreamProtocol.eventStreamV1,
              requestId: 'req-legacy',
              messageId: 'assistant-legacy',
              resumeToken: 'resume-legacy',
              messageMetadata: const {
                'serverOwned': true,
              },
              leadingDataParts: const [
                DataUiPart<Object?>(
                  id: 'progress',
                  key: 'status',
                  data: {
                    'value': 0.5,
                  },
                ),
              ],
              finalMessageMetadata: const {
                'persisted': true,
              },
            ),
          )
          .toList();

      final chunks = payloads
          .map<Object?>((payload) => payload)
          .map(chunkCodec.decodeChunk)
          .toList(growable: false);

      final start = chunks[0] as HttpChatTransportStartChunk;
      expect(start.requestId, 'req-legacy');
      expect(start.messageId, 'assistant-legacy');
      expect(start.resumeToken, 'resume-legacy');

      final dataPart = chunks[1] as HttpChatTransportDataPartChunk;
      expect(dataPart.part.id, 'progress');
      expect(dataPart.part.key, 'status');
      expect(
        (dataPart.part.data as Map<String, Object?>)['value'],
        0.5,
      );

      expect((chunks[2] as HttpChatTransportEventChunk).event,
          isA<TextStartEvent>());
      expect(
        ((chunks[3] as HttpChatTransportEventChunk).event as TextDeltaEvent)
            .delta,
        'Hello',
      );
      expect(
          (chunks[4] as HttpChatTransportEventChunk).event, isA<FinishEvent>());
      expect(chunks[5], isA<HttpChatTransportFinishChunk>());
    });

    test('maps message-start without message id into a v2 metadata patch',
        () async {
      const adapter = HttpChatTransportServerAdapter();

      final chunks = await adapter
          .encodeUiChunkStream(
            stream: Stream.fromIterable([
              ChatUiMessageStartChunk(
                metadata: const {
                  'phase': 'streaming',
                },
              ),
              const ChatUiEventChunk(
                TextStartEvent(id: 'text-1'),
              ),
            ]),
          )
          .toList();

      final metadataChunk = chunks[0] as HttpChatTransportMessageMetadataChunk;
      expect(metadataChunk.metadata['phase'], 'streaming');
      expect((chunks[1] as HttpChatTransportEventChunk).event,
          isA<TextStartEvent>());
      expect(chunks[2], isA<HttpChatTransportFinishChunk>());
    });

    test('encodes transient data chunks only for v2 streams', () async {
      const adapter = HttpChatTransportServerAdapter();

      final v2Chunks = await adapter
          .encodeUiChunkStream(
            stream: Stream.fromIterable([
              const ChatUiTransientDataPartChunk<Object?>(
                DataUiPart<Object?>(
                  id: 'heartbeat',
                  key: 'tool-status',
                  data: {
                    'phase': 'running',
                  },
                ),
              ),
            ]),
          )
          .toList();

      expect(v2Chunks[0], isA<HttpChatTransportTransientDataPartChunk>());
      expect(v2Chunks[1], isA<HttpChatTransportFinishChunk>());

      final v1Chunks = await adapter
          .encodeUiChunkStream(
            streamProtocol: HttpChatTransportStreamProtocol.eventStreamV1,
            requestId: 'req-legacy',
            stream: Stream.fromIterable([
              const ChatUiTransientDataPartChunk<Object?>(
                DataUiPart<Object?>(
                  id: 'heartbeat',
                  key: 'tool-status',
                  data: {
                    'phase': 'running',
                  },
                ),
              ),
            ]),
          )
          .toList();

      expect(v1Chunks, hasLength(2));
      expect(v1Chunks[0], isA<HttpChatTransportStartChunk>());
      expect(v1Chunks[1], isA<HttpChatTransportFinishChunk>());
    });
  });
}
