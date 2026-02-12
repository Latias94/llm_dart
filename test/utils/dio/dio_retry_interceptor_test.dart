import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

class _SequenceAdapter implements HttpClientAdapter {
  final List<int> statusCodes;
  final Map<String, List<String>> errorHeaders;
  int callCount = 0;

  _SequenceAdapter(this.statusCodes, {Map<String, List<String>>? errorHeaders})
      : errorHeaders = errorHeaders ?? const {'retry-after': ['0']};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = callCount;
    callCount++;

    final statusCode =
        index < statusCodes.length ? statusCodes[index] : statusCodes.last;

    if (statusCode == 200) {
      return ResponseBody.fromString(
        jsonEncode({'ok': true, 'attempt': index}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'error': 'status_$statusCode', 'attempt': index}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...errorHeaders,
      },
    );
  }
}

void main() {
  group('HttpRetryInterceptor', () {
    test('HttpConfigUtils installs retry interceptor when enabled', () {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'k',
        model: 'm',
      ).withTransportOptions({
        'retry': {
          'maxRetries': 2,
          'baseDelayMs': 0,
          'maxDelayMs': 0,
          'jitter': 0.0,
          'respectRetryAfter': true,
        },
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1/',
        defaultHeaders: {'Authorization': 'Bearer k'},
        config: config,
      );

      expect(dio.interceptors.any((i) => i is HttpRetryInterceptor), isTrue);
    });

    test('retries on 429 and succeeds', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'k',
        model: 'm',
      ).withTransportOptions({
        'retry': {
          'maxRetries': 2,
          'baseDelayMs': 0,
          'maxDelayMs': 0,
          'jitter': 0.0,
          'respectRetryAfter': true,
        },
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1/',
        defaultHeaders: {'Authorization': 'Bearer k'},
        config: config,
      );

      final adapter = _SequenceAdapter([429, 200]);
      dio.httpClientAdapter = adapter;

      final response = await dio.get('/test');
      expect(response.statusCode, equals(200));
      expect(adapter.callCount, equals(2));
    });

    test('prefers retry-after-ms when present', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'k',
        model: 'm',
      ).withTransportOptions({
        'retry': {
          'maxRetries': 1,
          'baseDelayMs': 2000, // would be used if retry-after-ms is ignored
          'maxDelayMs': 2000,
          'jitter': 0.0,
          'respectRetryAfter': true,
        },
      });

      Duration? slept;
      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1/',
        defaultHeaders: {'Authorization': 'Bearer k'},
        config: config,
      );
      // Replace the interceptor with a deterministic sleeper so the test is fast.
      dio.interceptors.removeWhere((i) => i is HttpRetryInterceptor);
      dio.interceptors.add(
        HttpRetryInterceptor(
          dio: dio,
          config: HttpRetryConfig.fromLLMConfig(config),
          sleep: (d) async {
            slept = d;
          },
        ),
      );

      dio.httpClientAdapter = _SequenceAdapter(
        [429, 200],
        errorHeaders: const {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'retry-after-ms': ['123'],
          'retry-after': ['2'],
        },
      );

      final response = await dio.get('/test');
      expect(response.statusCode, equals(200));
      expect(slept, equals(const Duration(milliseconds: 123)));
    });

    test('ignores unreasonable retry-after and falls back to backoff', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'k',
        model: 'm',
      ).withTransportOptions({
        'retry': {
          'maxRetries': 1,
          'baseDelayMs': 2000,
          'maxDelayMs': 2000,
          'jitter': 0.0,
          'respectRetryAfter': true,
        },
      });

      Duration? slept;
      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1/',
        defaultHeaders: {'Authorization': 'Bearer k'},
        config: config,
      );
      dio.interceptors.removeWhere((i) => i is HttpRetryInterceptor);
      dio.interceptors.add(
        HttpRetryInterceptor(
          dio: dio,
          config: HttpRetryConfig.fromLLMConfig(config),
          sleep: (d) async {
            slept = d;
          },
        ),
      );

      dio.httpClientAdapter = _SequenceAdapter(
        [429, 200],
        errorHeaders: const {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'retry-after': ['120'], // > 60s should be ignored
        },
      );

      final response = await dio.get('/test');
      expect(response.statusCode, equals(200));
      expect(slept, equals(const Duration(milliseconds: 2000)));
    });

    test('does not retry streaming requests', () async {
      final config = LLMConfig(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'k',
        model: 'm',
      ).withTransportOptions({
        'retry': {
          'maxRetries': 2,
          'baseDelayMs': 0,
          'maxDelayMs': 0,
          'jitter': 0.0,
          'respectRetryAfter': true,
        },
      });

      final dio = HttpConfigUtils.createConfiguredDio(
        baseUrl: 'https://api.example.com/v1/',
        defaultHeaders: {'Authorization': 'Bearer k'},
        config: config,
      );

      final adapter = _SequenceAdapter([500, 200]);
      dio.httpClientAdapter = adapter;

      await expectLater(
        () => dio.get(
          '/stream',
          options: Options(responseType: ResponseType.stream),
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, equals(1));
    });

    test('DioClientFactory installs retry interceptor for custom Dio', () {
      final customDio = Dio();
      customDio.options.baseUrl = 'https://custom.example.com/v1/';

      final llmConfig = LLMConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      ).withTransportOptions({
        'customDio': customDio,
        'retry': {
          'maxRetries': 1,
          'baseDelayMs': 0,
          'maxDelayMs': 0,
          'jitter': 0.0,
          'respectRetryAfter': true,
        },
      });

      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      final dio = DioClientFactory.create(
        strategy: AnthropicDioStrategy(),
        config: config,
      );

      expect(dio, same(customDio));
      expect(dio.interceptors.any((i) => i is HttpRetryInterceptor), isTrue);
    });
  });
}
