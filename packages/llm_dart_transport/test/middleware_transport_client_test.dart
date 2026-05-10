import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('MiddlewareTransportClient', () {
    test('send middleware can mutate request and response', () async {
      TransportRequest? capturedRequest;
      final client = MiddlewareTransportClient(
        inner: _FakeTransportClient(
          onSend: (request) {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              headers: {'x-inner': 'true'},
              body: {'ok': true},
            );
          },
        ),
        middlewares: [
          TransportMiddleware(
            onRequest: (request) => request.copyWith(
              headers: {
                ...request.headers,
                'x-trace-id': 'trace_1',
              },
              body: {
                'wrapped': request.body,
              },
            ),
            onResponse: (request, response) => response.copyWith(
              headers: {
                ...response.headers,
                'x-observed': request.headers['x-trace-id']!,
              },
            ),
          ),
        ],
      );

      final response = await client.send(
        TransportRequest(
          uri: Uri.parse('https://example.com/chat'),
          method: TransportMethod.post,
          headers: const {'x-request': 'original'},
          body: const {'message': 'hello'},
        ),
      );

      expect(capturedRequest?.headers, {
        'x-request': 'original',
        'x-trace-id': 'trace_1',
      });
      expect(capturedRequest?.body, {
        'wrapped': {'message': 'hello'},
      });
      expect(response.headers, {
        'x-inner': 'true',
        'x-observed': 'trace_1',
      });
    });

    test('sendStream middleware can mutate request and observe setup response',
        () async {
      TransportRequest? capturedRequest;
      final client = MiddlewareTransportClient(
        inner: _FakeTransportClient(
          onSendStream: (request) {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              headers: const {'content-type': 'text/event-stream'},
              stream: Stream.value(utf8.encode('chunk')),
            );
          },
        ),
        middlewares: [
          TransportMiddleware(
            onRequest: (request) => request.copyWith(
              headers: {
                ...request.headers,
                'accept': 'text/event-stream',
              },
            ),
            onStreamResponse: (request, response) => response.copyWith(
              headers: {
                ...response.headers,
                'x-stream-observed': request.headers['accept']!,
              },
            ),
          ),
        ],
      );

      final response = await client.sendStream(
        TransportRequest(
          uri: Uri.parse('https://example.com/stream'),
          method: TransportMethod.post,
        ),
      );
      final bytes = await response.stream.expand((chunk) => chunk).toList();

      expect(capturedRequest?.headers, {'accept': 'text/event-stream'});
      expect(response.headers['x-stream-observed'], 'text/event-stream');
      expect(utf8.decode(bytes), 'chunk');
    });

    test('error middleware can observe and replace errors', () async {
      Object? observedError;
      final client = MiddlewareTransportClient(
        inner: _FakeTransportClient(
          onSend: (_) => throw const TransportNetworkException('offline'),
        ),
        middlewares: [
          TransportMiddleware(
            onError: (request, error, stackTrace) {
              observedError = error;
              return StateError('mapped ${request.uri.host}');
            },
          ),
        ],
      );

      await expectLater(
        client.send(
          TransportRequest(
            uri: Uri.parse('https://example.com/chat'),
            method: TransportMethod.post,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'mapped example.com',
          ),
        ),
      );
      expect(observedError, isA<TransportNetworkException>());
    });
  });
}

final class _FakeTransportClient implements TransportClient {
  final FutureOr<TransportResponse> Function(TransportRequest request)? onSend;
  final FutureOr<StreamingTransportResponse> Function(TransportRequest request)?
      onSendStream;

  const _FakeTransportClient({
    this.onSend,
    this.onSendStream,
  });

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    final callback = onSend;
    if (callback == null) {
      throw UnsupportedError('send is not implemented');
    }
    return callback(request);
  }

  @override
  Future<StreamingTransportResponse> sendStream(
    TransportRequest request,
  ) async {
    final callback = onSendStream;
    if (callback == null) {
      throw UnsupportedError('sendStream is not implemented');
    }
    return callback(request);
  }
}
