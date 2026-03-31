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
      expect(start.request.uri.toString(), 'https://example.com/chat');
      expect(start.request.isStreaming, isFalse);
      expect(start.request.hasBody, isTrue);
      expect(start.request.bodyType, contains('Map'));
      expect(start.request.headerNames, ['authorization', 'x-trace-id']);

      final success = events[1];
      expect(success.kind, TransportDiagnosticsEventKind.requestSuccess);
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
      expect(events[0].request.isStreaming, isTrue);
      expect(events[1].kind, TransportDiagnosticsEventKind.requestSuccess);
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

      final failure = events[1];
      expect(failure.kind, TransportDiagnosticsEventKind.requestFailure);
      expect(failure.response?.statusCode, 502);
      expect(failure.response?.headerNames, ['retry-after']);
      expect(failure.error, isA<TransportHttpException>());
      expect(failure.duration, isNotNull);
    });
  });
}
