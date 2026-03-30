import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/providers/openai/dio_strategy.dart';
import 'package:llm_dart/src/compatibility/compat_transport.dart';
import 'package:llm_dart/utils/dio_client_factory.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('Compat Transport', () {
    test('returns custom transport client when provided', () {
      final customTransport = _FakeTransportClient();
      final config = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/',
        model: 'gpt-4o',
      ).withExtension('customTransportClient', customTransport);

      final transport = createCompatTransport(config);

      expect(transport, same(customTransport));
    });

    test('prefers custom transport client over custom Dio', () {
      final customTransport = _FakeTransportClient();
      final customDio = Dio();
      final config = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/',
        model: 'gpt-4o',
      ).withExtensions({
        'customTransportClient': customTransport,
        'customDio': customDio,
      });

      final transport = createCompatTransport(config);

      expect(transport, same(customTransport));
    });

    test('legacy Dio factory reuses Dio from a Dio-backed transport client',
        () {
      final customDio = Dio();
      final customTransport = DioTransportClient(dio: customDio);
      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/',
        model: 'gpt-4o',
      ).withExtension('customTransportClient', customTransport);

      final dio = DioClientFactory.create(
        strategy: OpenAIDioStrategy(),
        config: OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com/',
          model: 'gpt-4o',
          originalConfig: originalConfig,
        ),
      );

      expect(dio, same(customDio));
    });
  });
}

final class _FakeTransportClient implements TransportClient {
  @override
  Future<TransportResponse> send(TransportRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<StreamingTransportResponse> sendStream(
      TransportRequest request) async {
    throw UnimplementedError();
  }
}
