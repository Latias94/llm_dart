import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('sendProviderModelRequest', () {
    test('ProviderCallKit sends model requests through the same policy',
        () async {
      final kit = ProviderCallKit(
        transport: _FakeTransportClient(
          sendHandler: (request) async => TransportResponse(
            statusCode: 200,
            headers: const {'x-model': 'ok'},
            body: {'value': request.uri.path},
          ),
        ),
      );

      final result = await kit.sendModelRequest<String>(
        request: TransportRequest(
          method: TransportMethod.post,
          uri: Uri.parse('https://example.test/models'),
        ),
        decode: (body, headers) {
          final map = body! as Map<String, Object?>;
          return '${headers['x-model']}:${map['value']}';
        },
      );

      expect(result, 'ok:/models');
    });

    test('sends transport request and decodes body plus headers', () async {
      final request = _jsonRequest();
      final transport = _FakeTransportClient(
        sendHandler: (actualRequest) async {
          expect(actualRequest, same(request));
          return const TransportResponse(
            statusCode: 200,
            headers: {'x-request-id': 'req-1'},
            body: {'text': 'hello'},
          );
        },
      );

      final result = await sendProviderModelRequest<String>(
        transport: transport,
        request: request,
        decode: (body, headers) {
          expect(headers, {'x-request-id': 'req-1'});
          return (body as Map<String, Object?>)['text']! as String;
        },
      );

      expect(result, 'hello');
    });

    test('normalizes transport cancellation into provider cancellation',
        () async {
      final providerCancellation = ProviderCancellation()..cancel('user');
      final request = _jsonRequest(
        cancellation: TransportCancellation(source: providerCancellation),
      );
      final transport = _FakeTransportClient(
        sendHandler: (_) async => throw const TransportCancelledException(
          'transport',
        ),
      );

      await expectLater(
        sendProviderModelRequest<Object?>(
          transport: transport,
          request: request,
          decode: (body, _) => body,
        ),
        throwsA(
          isA<ProviderCancelledException>().having(
            (error) => error.reason,
            'reason',
            'transport',
          ),
        ),
      );
    });
  });

  group('sendProviderLanguageModelStreamRequest', () {
    test('ProviderCallKit streams with shared start and error projection',
        () async {
      final kit = ProviderCallKit(
        transport: _FakeTransportClient(
          sendStreamHandler: (_) async => throw TransportHttpException(
            'bad gateway',
            statusCode: 502,
          ),
        ),
      );

      final events = await kit
          .sendLanguageModelStreamRequest(
            request: TransportRequest(
              method: TransportMethod.post,
              uri: Uri.parse('https://example.test/stream'),
            ),
            warnings: const [],
            includeRawChunks: false,
            decode: ({required stream, required includeRawChunks}) async* {},
          )
          .toList();

      expect(events.first, isA<StartEvent>());
      final error = (events.last as ErrorEvent).error;
      expect(error.kind, ModelErrorKind.transport);
      expect(error.statusCode, 502);
    });

    test('emits StartEvent before decoded stream events', () async {
      final request = _jsonRequest();
      final warning = const ModelWarning(
        type: ModelWarningType.unsupported,
        message: 'not supported',
        feature: 'topK',
      );
      final transport = _FakeTransportClient(
        sendStreamHandler: (actualRequest) async {
          expect(actualRequest, same(request));
          return StreamingTransportResponse(
            statusCode: 200,
            stream: Stream.fromIterable([utf8.encode('hello')]),
          );
        },
      );

      final events = await sendProviderLanguageModelStreamRequest(
        transport: transport,
        request: request,
        warnings: [warning],
        includeRawChunks: true,
        decode: ({required stream, required includeRawChunks}) async* {
          expect(includeRawChunks, isTrue);
          await for (final bytes in stream) {
            yield TextDeltaEvent(
              id: 'text',
              delta: utf8.decode(bytes),
            );
          }
        },
      ).toList();

      expect(events, hasLength(2));
      expect(events[0], isA<StartEvent>());
      expect((events[0] as StartEvent).warnings, [warning]);
      expect(events[1], isA<TextDeltaEvent>());
      expect((events[1] as TextDeltaEvent).delta, 'hello');
    });

    test('projects stream transport errors into ErrorEvent', () async {
      final transport = _FakeTransportClient(
        sendStreamHandler: (_) async => throw TransportHttpException(
          'bad gateway',
          statusCode: 502,
          uri: Uri.parse('https://example.com/chat'),
        ),
      );

      final events = await sendProviderLanguageModelStreamRequest(
        transport: transport,
        request: _jsonRequest(),
        warnings: const [],
        includeRawChunks: false,
        decode: ({required stream, required includeRawChunks}) async* {
          fail('decode should not run after transport failure');
        },
      ).toList();

      expect(events, hasLength(2));
      expect(events[0], isA<StartEvent>());
      expect(events[1], isA<ErrorEvent>());
      final error = (events[1] as ErrorEvent).error;
      expect(error.kind, ModelErrorKind.transport);
      expect(error.code, 'transport-http');
      expect(error.statusCode, 502);
      expect(error.isRetryable, isTrue);
    });
  });
}

TransportRequest _jsonRequest({
  TransportCancellation? cancellation,
}) {
  return TransportRequest(
    uri: Uri.parse('https://example.com/v1/models'),
    method: TransportMethod.post,
    cancellation: cancellation,
  );
}

final class _FakeTransportClient implements TransportClient {
  final Future<TransportResponse> Function(TransportRequest request)?
      sendHandler;
  final Future<StreamingTransportResponse> Function(TransportRequest request)?
      sendStreamHandler;

  const _FakeTransportClient({
    this.sendHandler,
    this.sendStreamHandler,
  });

  @override
  Future<TransportResponse> send(TransportRequest request) {
    final handler = sendHandler;
    if (handler == null) {
      throw StateError('send was not expected');
    }
    return handler(request);
  }

  @override
  Future<StreamingTransportResponse> sendStream(TransportRequest request) {
    final handler = sendStreamHandler;
    if (handler == null) {
      throw StateError('sendStream was not expected');
    }
    return handler(request);
  }
}
