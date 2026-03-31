import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('DioTransportClient diagnostics', () {
    test('send emits start and success events', () async {
      final events = <TransportDiagnosticsEvent>[];
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                headers: Headers.fromMap({
                  'x-request-id': ['req_1'],
                }),
                data: {
                  'ok': true,
                },
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        diagnostics: CallbackTransportDiagnostics(events.add),
      );

      final response = await client.send(
        TransportRequest(
          uri: Uri.parse('https://example.com/chat'),
          method: TransportMethod.post,
          headers: const {
            'authorization': 'Bearer secret',
            'x-trace-id': 'trace_1',
          },
          body: const {
            'message': 'hello',
          },
        ),
      );

      expect(response.statusCode, 200);
      expect(events, hasLength(2));

      final start = events[0];
      expect(start.kind, TransportDiagnosticsEventKind.requestStart);
      expect(start.attempt, 1);
      expect(start.request.uri.toString(), 'https://example.com/chat');
      expect(start.request.isStreaming, isFalse);
      expect(start.request.hasBody, isTrue);
      expect(start.request.bodyType, contains('Map'));
      expect(start.request.headerNames, ['authorization', 'x-trace-id']);

      final success = events[1];
      expect(success.kind, TransportDiagnosticsEventKind.requestSuccess);
      expect(success.attempt, 1);
      expect(success.response?.statusCode, 200);
      expect(success.response?.headerNames, ['x-request-id']);
      expect(success.duration, isNotNull);
    });

    test('sendStream emits start and success events', () async {
      final events = <TransportDiagnosticsEvent>[];
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                headers: Headers.fromMap({
                  'content-type': ['text/event-stream'],
                }),
                data: ResponseBody(
                  Stream.fromIterable([
                    utf8.encode('chunk'),
                  ]),
                  200,
                ),
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        diagnostics: CallbackTransportDiagnostics(events.add),
      );

      final response = await client.sendStream(
        TransportRequest(
          uri: Uri.parse('https://example.com/stream'),
          method: TransportMethod.post,
        ),
      );

      final bytes = await response.stream.expand((chunk) => chunk).toList();
      expect(utf8.decode(bytes), 'chunk');
      expect(events, hasLength(2));
      expect(events[0].kind, TransportDiagnosticsEventKind.requestStart);
      expect(events[0].attempt, 1);
      expect(events[0].request.isStreaming, isTrue);
      expect(events[1].kind, TransportDiagnosticsEventKind.requestSuccess);
      expect(events[1].attempt, 1);
      expect(events[1].response?.statusCode, 200);
      expect(events[1].response?.headerNames, ['content-type']);
    });

    test('send emits failure events for HTTP errors', () async {
      final events = <TransportDiagnosticsEvent>[];
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 502,
                headers: Headers.fromMap({
                  'retry-after': ['1'],
                }),
                data: {
                  'message': 'upstream failed',
                },
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        diagnostics: CallbackTransportDiagnostics(events.add),
      );

      await expectLater(
        client.send(
          TransportRequest(
            uri: Uri.parse('https://example.com/chat'),
            method: TransportMethod.post,
          ),
        ),
        throwsA(isA<TransportHttpException>()),
      );

      expect(events, hasLength(2));
      expect(events[0].kind, TransportDiagnosticsEventKind.requestStart);
      expect(events[0].attempt, 1);

      final failure = events[1];
      expect(failure.kind, TransportDiagnosticsEventKind.requestFailure);
      expect(failure.attempt, 1);
      expect(failure.response?.statusCode, 502);
      expect(failure.response?.headerNames, ['retry-after']);
      expect(failure.error, isA<TransportHttpException>());
      expect(failure.duration, isNotNull);
    });
  });

  group('DioTransportClient retry', () {
    test('retries timeout failures and eventually succeeds', () async {
      var attempts = 0;
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            if (attempts == 1) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.receiveTimeout,
                  message: 'timed out',
                ),
              );
              return;
            }

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'ok': true,
                },
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        retryPolicy: const TransportRetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration.zero,
        ),
      );

      final response = await client.send(
        TransportRequest(
          uri: Uri.parse('https://example.com/chat'),
          method: TransportMethod.post,
        ),
      );

      expect(response.statusCode, 200);
      expect(attempts, 2);
    });

    test('retries retryable HTTP status and records attempt diagnostics',
        () async {
      final events = <TransportDiagnosticsEvent>[];
      var attempts = 0;
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            if (attempts == 1) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 429,
                  headers: Headers.fromMap({
                    'retry-after': ['0'],
                  }),
                  data: {
                    'message': 'rate limited',
                  },
                ),
              );
              return;
            }

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'ok': true,
                },
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        diagnostics: CallbackTransportDiagnostics(events.add),
        retryPolicy: const TransportRetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration.zero,
        ),
      );

      final response = await client.send(
        TransportRequest(
          uri: Uri.parse('https://example.com/chat'),
          method: TransportMethod.post,
        ),
      );

      expect(response.statusCode, 200);
      expect(attempts, 2);
      expect(events, hasLength(4));
      expect(
        events.map((event) => event.kind),
        [
          TransportDiagnosticsEventKind.requestStart,
          TransportDiagnosticsEventKind.requestFailure,
          TransportDiagnosticsEventKind.requestStart,
          TransportDiagnosticsEventKind.requestSuccess,
        ],
      );
      expect(
        events.map((event) => event.attempt),
        [1, 1, 2, 2],
      );
    });

    test('does not retry non-retryable HTTP status', () async {
      var attempts = 0;
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 400,
                data: {
                  'message': 'bad request',
                },
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        retryPolicy: const TransportRetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration.zero,
        ),
      );

      await expectLater(
        client.send(
          TransportRequest(
            uri: Uri.parse('https://example.com/chat'),
            method: TransportMethod.post,
          ),
        ),
        throwsA(isA<TransportHttpException>()),
      );

      expect(attempts, 1);
    });

    test('cancellation stops retries during backoff', () async {
      var attempts = 0;
      final cancellation = TransportCancellation();
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 503,
                data: {
                  'message': 'busy',
                },
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        retryPolicy: const TransportRetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 100),
        ),
      );

      Future<void>.delayed(
        const Duration(milliseconds: 20),
        () => cancellation.cancel('stop'),
      );

      await expectLater(
        client.send(
          TransportRequest(
            uri: Uri.parse('https://example.com/chat'),
            method: TransportMethod.post,
            cancellation: cancellation,
          ),
        ),
        throwsA(isA<TransportCancelledException>()),
      );

      expect(attempts, 1);
    });

    test('retries stream setup failures before returning stream', () async {
      var attempts = 0;
      final dio = Dio(
        BaseOptions(
          validateStatus: (_) => true,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            if (attempts == 1) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 503,
                  data: 'busy',
                ),
              );
              return;
            }

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                headers: Headers.fromMap({
                  'content-type': ['text/event-stream'],
                }),
                data: ResponseBody(
                  Stream.fromIterable([
                    utf8.encode('chunk'),
                  ]),
                  200,
                ),
              ),
            );
          },
        ),
      );

      final client = DioTransportClient(
        dio: dio,
        retryPolicy: const TransportRetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration.zero,
        ),
      );

      final response = await client.sendStream(
        TransportRequest(
          uri: Uri.parse('https://example.com/stream'),
          method: TransportMethod.post,
        ),
      );

      final bytes = await response.stream.expand((chunk) => chunk).toList();
      expect(utf8.decode(bytes), 'chunk');
      expect(attempts, 2);
    });
  });
}
