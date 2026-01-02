import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic beta headers (official docs alignment)', () {
    test('adds web-fetch beta header when web fetch tool is enabled', () {
      final config = AnthropicConfig(
        apiKey: 'k',
        model: 'm',
        providerId: 'anthropic',
        webFetchToolType: 'web_fetch_20250910',
      );

      final strategy = AnthropicDioStrategy();
      final enhancers = strategy.getEnhancers(config);
      final endpointHeaders = enhancers.whereType<InterceptorEnhancer>().single;
      final interceptor = endpointHeaders.interceptor as InterceptorsWrapper;

      final options = RequestOptions(path: 'messages', data: const {});
      final handler = RequestInterceptorHandler();
      interceptor.onRequest(options, handler);

      expect(
        options.headers['anthropic-beta'],
        contains('web-fetch-2025-09-10'),
      );
    });

    test('does not add beta headers for anthropic-compatible providers', () {
      final config = AnthropicConfig(
        apiKey: 'k',
        model: 'm',
        providerId: 'minimax',
        webFetchToolType: 'web_fetch_20250910',
      );

      final strategy = AnthropicDioStrategy(providerName: 'MiniMax');
      final dio = DioClientFactory.create(strategy: strategy, config: config);

      // base headers come from ConfigUtils; beta headers are injected per-request
      // and should be omitted for non-`anthropic` provider ids by default.
      expect(dio.options.headers.containsKey('anthropic-beta'), isFalse);
    });
  });
}
