import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_chat/src/http_chat_transport_resume_state.dart';
import 'package:llm_dart_chat/src/http_chat_transport_stream_client.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportStreamClient', () {
    test('decodes SSE transport chunks and records replay state', () async {
      const chunkCodec = HttpChatTransportChunkJsonCodec();
      final state = _resumeState();
      var cleared = false;

      final client = HttpChatTransportStreamClient(
        transport: FakeTransportClient(
          onSendStream: (_) async => StreamingTransportResponse(
            statusCode: 200,
            stream: Stream.fromIterable([
              _sseFrame(
                chunkCodec.encodeChunk(
                  const HttpChatTransportStartChunk(
                    messageId: 'msg-1',
                    resumeToken: 'resume-1',
                  ),
                ),
              ),
              _sseFrame(
                chunkCodec.encodeChunk(
                  const HttpChatTransportEventChunk(
                    TextDeltaEvent(id: 'text-1', delta: 'Hello'),
                  ),
                ),
              ),
            ]),
          ),
        ),
        sseDecoder: const DefaultSseDecoder(),
        chunkCodec: chunkCodec,
      );

      final chunks = await client
          .sendPayload(
            state: state,
            endpoint: Uri.parse('https://example.com/chat'),
            headers: const {},
            requestTimeout: null,
            maxRetries: null,
            cancellation: null,
            payload: const {},
            clearResumeState: () => cleared = true,
          )
          .toList();

      expect(chunks.first, isA<ChatUiMessageStartChunk>());
      expect(
        (chunks.last as ChatUiEventChunk).event,
        isA<TextDeltaEvent>().having(
          (event) => event.delta,
          'delta',
          'Hello',
        ),
      );
      expect(state.resumeToken, 'resume-1');
      expect(state.replayChunks, hasLength(2));
      expect(cleared, isFalse);
    });

    test('maps HTTP status failures to terminal transport errors', () async {
      final state = _resumeState();
      var cleared = false;

      final client = HttpChatTransportStreamClient(
        transport: FakeTransportClient(
          onSendStream: (_) async => StreamingTransportResponse(
            statusCode: 503,
            stream: const Stream<List<int>>.empty(),
          ),
        ),
        sseDecoder: const DefaultSseDecoder(),
        chunkCodec: const HttpChatTransportChunkJsonCodec(),
      );

      final event = await client
          .sendPayload(
            state: state,
            endpoint: Uri.parse('https://example.com/chat'),
            headers: const {},
            requestTimeout: null,
            maxRetries: null,
            cancellation: null,
            payload: const {},
            clearResumeState: () => cleared = true,
          )
          .where((chunk) => chunk is ChatUiEventChunk)
          .cast<ChatUiEventChunk>()
          .map((chunk) => chunk.event)
          .single;

      expect(event, isA<ErrorEvent>());
      final error = (event as ErrorEvent).error;
      expect(error.statusCode, 503);
      expect(error.isRetryable, isTrue);
      expect(cleared, isTrue);
    });

    test('keeps reconnectable state after stream errors', () async {
      const chunkCodec = HttpChatTransportChunkJsonCodec();
      final state = _resumeState();
      var cleared = false;

      final client = HttpChatTransportStreamClient(
        transport: FakeTransportClient(
          onSendStream: (_) async => StreamingTransportResponse(
            statusCode: 200,
            stream: Stream<List<int>>.multi((controller) {
              controller.add(
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportCheckpointChunk(
                      resumeToken: 'resume-1',
                    ),
                  ),
                ),
              );
              controller.addError(StateError('socket closed'));
            }),
          ),
        ),
        sseDecoder: const DefaultSseDecoder(),
        chunkCodec: chunkCodec,
      );

      final event = await client
          .sendPayload(
            state: state,
            endpoint: Uri.parse('https://example.com/chat'),
            headers: const {},
            requestTimeout: null,
            maxRetries: null,
            cancellation: null,
            payload: const {},
            clearResumeState: () => cleared = true,
          )
          .where((chunk) => chunk is ChatUiEventChunk)
          .cast<ChatUiEventChunk>()
          .map((chunk) => chunk.event)
          .single;

      expect(event, isA<ErrorEvent>());
      expect(state.canReconnect, isTrue);
      expect(cleared, isFalse);
    });
  });
}

HttpChatTransportResumeState _resumeState() {
  return HttpChatTransportResumeState(
    callOptionsPayload: HttpChatTransportCallOptionsPayload(),
    requestTimeout: null,
    maxRetries: null,
    cancellation: null,
  );
}

List<int> _sseFrame(Map<String, Object?> payload) {
  return utf8.encode('data: ${jsonEncode(payload)}\n\n');
}
