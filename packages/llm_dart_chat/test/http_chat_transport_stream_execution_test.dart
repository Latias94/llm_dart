import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_chat/src/http_chat_transport_stream_execution.dart';
import 'package:llm_dart_chat/src/http_chat_transport_stream_request.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('HTTP chat transport stream execution', () {
    test('builds the transport request for a prepared stream payload', () {
      final cancellation = ProviderCancellation();
      final request = buildHttpChatTransportStreamRequest(
        endpoint: Uri.parse('https://example.com/chat'),
        headers: const {
          'accept': 'text/event-stream',
          'content-type': 'application/json',
        },
        requestTimeout: const Duration(seconds: 3),
        maxRetries: 2,
        cancellation: cancellation,
        payload: const {
          'kind': 'llm_dart.chat.request',
        },
      );

      expect(request.uri, Uri.parse('https://example.com/chat'));
      expect(request.method, TransportMethod.post);
      expect(request.responseType, TransportResponseType.plainText);
      expect(request.timeout, const Duration(seconds: 3));
      expect(request.maxRetries, 2);
      expect(request.cancellation!.source, same(cancellation));
      expect(request.headers, containsPair('accept', 'text/event-stream'));
      expect(request.body, {
        'kind': 'llm_dart.chat.request',
      });
    });

    test('yields status failures before parsing the response stream', () async {
      final frames = await executeHttpChatTransportStream(
        transport: FakeTransportClient(
          onSendStream: (_) async => StreamingTransportResponse(
            statusCode: 503,
            stream: Stream.error(StateError('should not parse')),
          ),
        ),
        request: _request(),
        sseDecoder: const DefaultSseDecoder(),
        chunkCodec: const HttpChatTransportChunkJsonCodec(),
      ).toList();

      expect(frames, hasLength(1));
      expect(
        frames.single,
        isA<HttpChatTransportStreamStatusFailure>().having(
          (frame) => frame.statusCode,
          'statusCode',
          503,
        ),
      );
    });

    test('decodes SSE envelopes into transport chunks', () async {
      const chunkCodec = HttpChatTransportChunkJsonCodec();

      final frames = await executeHttpChatTransportStream(
        transport: FakeTransportClient(
          onSendStream: (_) async => StreamingTransportResponse(
            statusCode: 200,
            stream: Stream.fromIterable([
              _sseFrame(
                chunkCodec.encodeChunk(
                  const HttpChatTransportCheckpointChunk(
                    resumeToken: 'resume-1',
                  ),
                ),
              ),
            ]),
          ),
        ),
        request: _request(),
        sseDecoder: const DefaultSseDecoder(),
        chunkCodec: chunkCodec,
      ).toList();

      expect(frames, hasLength(1));
      final received = frames.single as HttpChatTransportStreamReceivedChunk;
      expect(received.chunk, isA<HttpChatTransportCheckpointChunk>());
      expect(
        (received.chunk as HttpChatTransportCheckpointChunk).resumeToken,
        'resume-1',
      );
    });

    test('labels malformed SSE JSON with the HTTP chat transport source',
        () async {
      await expectLater(
        executeHttpChatTransportStream(
          transport: FakeTransportClient(
            onSendStream: (_) async => StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode('data: {"broken":\n\n'),
              ]),
            ),
          ),
          request: _request(),
          sseDecoder: const DefaultSseDecoder(),
          chunkCodec: const HttpChatTransportChunkJsonCodec(),
        ).drain<void>(),
        throwsA(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains('HTTP chat transport stream API returned invalid JSON'),
          ),
        ),
      );
    });
  });
}

TransportRequest _request() {
  return buildHttpChatTransportStreamRequest(
    endpoint: Uri.parse('https://example.com/chat'),
    headers: const {
      'accept': 'text/event-stream',
    },
    requestTimeout: null,
    maxRetries: null,
    cancellation: null,
    payload: const {},
  );
}

List<int> _sseFrame(Map<String, Object?> payload) {
  return utf8.encode('data: ${jsonEncode(payload)}\n\n');
}
