import 'package:test/test.dart';

import 'package:dio/dio.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_elevenlabs/config.dart';
import 'package:llm_dart_elevenlabs/dio_strategy.dart';
import 'package:llm_dart_google/config.dart';
import 'package:llm_dart_google/dio_strategy.dart';
import 'package:llm_dart_ollama/config.dart';
import 'package:llm_dart_ollama/dio_strategy.dart';
import 'package:llm_dart_azure/config.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/dio_strategy.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('DioClientFactory', () {
    String? headerValueIgnoreCase(
      Map<String, dynamic> headers,
      String headerName,
    ) {
      final needle = headerName.toLowerCase();
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == needle) {
          return entry.value?.toString();
        }
      }
      return null;
    }

    test('should create Dio client with Anthropic strategy', () {
      final config = AnthropicConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      );

      final dio = DioClientFactory.create(
        strategy: AnthropicDioStrategy(),
        config: config,
      );

      expect(dio, isA<Dio>());
      expect(dio.options.baseUrl, equals('https://api.anthropic.com/v1/'));
      expect(dio.options.headers['x-api-key'], equals('test-key'));
      expect(dio.options.headers['anthropic-version'], equals('2023-06-01'));
      expect(
        headerValueIgnoreCase(dio.options.headers, 'user-agent'),
        equals(defaultUserAgentHeaderValueForProvider('anthropic')),
      );

      // Should have Anthropic-specific interceptors
      expect(dio.interceptors.length, greaterThan(0));
    });

    test('should create Dio client with OpenAI strategy', () {
      final config = OpenAIConfig(
        baseUrl: 'https://api.openai.com/v1/',
        apiKey: 'test-key',
        model: 'gpt-4',
      );

      final dio = DioClientFactory.create(
        strategy: OpenAIDioStrategy(),
        config: config,
      );

      expect(dio, isA<Dio>());
      expect(dio.options.baseUrl, equals('https://api.openai.com/v1/'));
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
      expect(
        headerValueIgnoreCase(dio.options.headers, 'user-agent'),
        equals(defaultUserAgentHeaderValueForProvider('openai')),
      );
    });

    test('should create Dio client with Google strategy', () {
      final config = GoogleConfig(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        apiKey: 'test-key',
        model: 'gemini-pro',
      );

      final dio = DioClientFactory.create(
        strategy: GoogleDioStrategy(),
        config: config,
      );

      expect(dio, isA<Dio>());
      expect(dio.options.baseUrl,
          equals('https://generativelanguage.googleapis.com/v1beta/'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
      expect(
        headerValueIgnoreCase(dio.options.headers, 'user-agent'),
        equals(defaultUserAgentHeaderValueForProvider('google')),
      );
      // Google uses query parameter auth, so no Authorization header
      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    });

    test('should use custom Dio when provided', () {
      final customDio = Dio();
      customDio.options.baseUrl = 'https://custom.example.com';
      customDio.options.headers['X-Custom'] = 'test';
      customDio.options.headers['user-agent'] = 'CorporateApp/2.0';

      final llmConfig = LLMConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      ).withTransportOptions({
        'customDio': customDio,
      });

      final config = AnthropicConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
        originalConfig: llmConfig,
      );

      final dio = DioClientFactory.create(
        strategy: AnthropicDioStrategy(),
        config: config,
      );

      // Should use the custom Dio instance
      expect(dio, same(customDio));
      expect(dio.options.headers['X-Custom'], equals('test'));
      expect(
        headerValueIgnoreCase(dio.options.headers, 'user-agent'),
        equals(
          'CorporateApp/2.0 ${defaultUserAgentHeaderValueForProvider('anthropic')}',
        ),
      );

      // Should still have essential Anthropic headers merged
      expect(dio.options.headers['x-api-key'], equals('test-key'));

      // Should have Anthropic-specific interceptors added
      expect(dio.interceptors.length, greaterThan(0));
    });

    test('should preserve custom interceptors when using custom Dio', () {
      final customDio = Dio();

      customDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Custom-Interceptor'] = 'active';
          handler.next(options);
        },
      ));

      final llmConfig = LLMConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      ).withTransportOptions({
        'customDio': customDio,
      });

      final config = AnthropicConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
        originalConfig: llmConfig,
      );

      final dio = DioClientFactory.create(
        strategy: AnthropicDioStrategy(),
        config: config,
      );

      // Should have both custom and provider interceptors
      expect(dio.interceptors.length, greaterThan(1));
    });
  });

  group('Provider Strategies', () {
    test('AnthropicDioStrategy should build correct headers', () {
      final config = AnthropicConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      );

      final strategy = AnthropicDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['x-api-key'], equals('test-key'));
      expect(headers['anthropic-version'], equals('2023-06-01'));
      expect(headers['Content-Type'], equals('application/json'));
      expect(
        headers['User-Agent'],
        equals(defaultUserAgentHeaderValueForProvider('anthropic')),
      );
    });

    test('OpenAIDioStrategy should build correct headers', () {
      final config = OpenAIConfig(
        baseUrl: 'https://api.openai.com/v1/',
        apiKey: 'test-key',
        model: 'gpt-4',
      );

      final strategy = OpenAIDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
      expect(
        headers['User-Agent'],
        equals(defaultUserAgentHeaderValueForProvider('openai')),
      );
    });

    test('GoogleDioStrategy should build correct headers', () {
      final config = GoogleConfig(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        apiKey: 'test-key',
        model: 'gemini-pro',
      );

      final strategy = GoogleDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['Content-Type'], equals('application/json'));
      expect(
        headers['User-Agent'],
        equals(defaultUserAgentHeaderValueForProvider('google')),
      );
      // Google doesn't use Authorization header
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('xAI should use standard OpenAI-compatible headers', () {
      final config = OpenAICompatibleConfig(
        providerId: 'xai',
        providerName: 'xAI',
        baseUrl: 'https://api.x.ai/v1/',
        apiKey: 'test-key',
        model: 'grok-3',
      );

      final strategy = OpenAIDioStrategy(providerName: 'xAI');
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
      expect(
        headers['User-Agent'],
        equals(defaultUserAgentHeaderValueForProvider('xai')),
      );
    });

    test('Groq should use standard OpenAI-compatible headers', () {
      final config = OpenAICompatibleConfig(
        providerId: 'groq',
        providerName: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1/',
        apiKey: 'test-key',
        model: 'llama-3.3-70b-versatile',
      );

      final strategy = OpenAIDioStrategy(providerName: 'Groq');
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['User-Agent'],
          equals(defaultUserAgentHeaderValueForProvider('groq')));
    });

    test('Azure OpenAI should use api-key header', () {
      final config = AzureOpenAIConfig(
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        apiKey: 'test-key',
        model: 'gpt-4o',
        apiVersion: '2024-10-01-preview',
      );

      final strategy = OpenAIDioStrategy(providerName: 'Azure OpenAI');
      final headers = strategy.buildHeaders(config);

      expect(headers['api-key'], equals('test-key'));
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('Azure OpenAI should attach api-version query parameter', () async {
      final config = AzureOpenAIConfig(
        baseUrl: 'https://example.openai.azure.com/openai/v1/',
        apiKey: 'test-key',
        model: 'gpt-4o',
        apiVersion: '2024-10-01-preview',
      );

      final strategy = OpenAIDioStrategy(providerName: 'Azure OpenAI');
      final dio = DioClientFactory.create(strategy: strategy, config: config);
      final adapter = _CapturingHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      await dio.get('/responses');

      final last = adapter.lastOptions;
      expect(last, isNotNull);
      expect(last!.uri.queryParameters['api-version'],
          equals('2024-10-01-preview'));
    });

    test('OllamaDioStrategy should build correct headers', () {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434/',
        apiKey: 'test-key',
        model: 'llama3.2',
      );

      final strategy = OllamaDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['User-Agent'],
          equals(defaultUserAgentHeaderValueForProvider('ollama')));
    });

    test('OllamaDioStrategy should handle null API key', () {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434/',
        apiKey: null,
        model: 'llama3.2',
      );

      final strategy = OllamaDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['User-Agent'],
          equals(defaultUserAgentHeaderValueForProvider('ollama')));
    });

    test('Phind should use standard OpenAI-compatible headers', () {
      final config = OpenAICompatibleConfig(
        providerId: 'phind',
        providerName: 'Phind',
        apiKey: 'test-key',
        baseUrl: 'https://api.phind.com/v1/',
        model: 'Phind-70B',
      );

      final strategy = OpenAIDioStrategy(providerName: 'Phind');
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
    });

    test('ElevenLabsDioStrategy should build correct headers', () {
      final config = ElevenLabsConfig(
        baseUrl: 'https://api.elevenlabs.io/v1/',
        apiKey: 'test-key',
      );

      final strategy = ElevenLabsDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['xi-api-key'], equals('test-key'));
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['User-Agent'],
          equals(defaultUserAgentHeaderValueForProvider('elevenlabs')));
    });
  });

  group('All Providers Priority Testing', () {
    test('should respect custom Dio priority for all providers', () {
      final customDio = Dio();
      customDio.options.baseUrl = 'https://custom.example.com';
      customDio.options.headers['X-Custom'] = 'test';

      final llmConfig = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'customDio': customDio,
      });

      // Test all provider strategies with custom Dio
      final providers = [
        {
          'strategy': AnthropicDioStrategy(),
          'config': AnthropicConfig.fromLLMConfig(llmConfig)
        },
        {
          'strategy': OpenAIDioStrategy(),
          'config': OpenAIConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': GoogleDioStrategy(),
          'config': GoogleConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'xAI'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'xai',
            providerName: 'xAI',
          )
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'Groq'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'groq',
            providerName: 'Groq',
          )
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'DeepSeek'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'deepseek',
            providerName: 'DeepSeek',
          )
        },
        {
          'strategy': OllamaDioStrategy(),
          'config': OllamaConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'Phind'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'phind',
            providerName: 'Phind',
          )
        },
        {
          'strategy': ElevenLabsDioStrategy(),
          'config': ElevenLabsConfig.fromLLMConfig(llmConfig)
        },
      ];

      for (final provider in providers) {
        final strategy = provider['strategy'] as ProviderDioStrategy;
        final config = provider['config'];

        final dio = DioClientFactory.create(
          strategy: strategy,
          config: config,
        );

        // Should use the same custom Dio instance
        expect(dio, same(customDio),
            reason: 'Provider ${strategy.providerName} should use custom Dio');
        expect(dio.options.headers['X-Custom'], equals('test'),
            reason:
                'Provider ${strategy.providerName} should preserve custom headers');
      }
    });

    test('should create new Dio when no custom Dio provided for all providers',
        () {
      final llmConfig = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      );

      final providers = [
        {
          'strategy': AnthropicDioStrategy(),
          'config': AnthropicConfig.fromLLMConfig(llmConfig)
        },
        {
          'strategy': OpenAIDioStrategy(),
          'config': OpenAIConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': GoogleDioStrategy(),
          'config': GoogleConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'xAI'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'xai',
            providerName: 'xAI',
          )
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'Groq'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'groq',
            providerName: 'Groq',
          )
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'DeepSeek'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'deepseek',
            providerName: 'DeepSeek',
          )
        },
        {
          'strategy': OllamaDioStrategy(),
          'config': OllamaConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'Phind'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'phind',
            providerName: 'Phind',
          )
        },
        {
          'strategy': ElevenLabsDioStrategy(),
          'config': ElevenLabsConfig.fromLLMConfig(llmConfig)
        },
      ];

      for (final provider in providers) {
        final strategy = provider['strategy'] as ProviderDioStrategy;
        final config = provider['config'];

        final dio = DioClientFactory.create(
          strategy: strategy,
          config: config,
        );

        // Should create new Dio instance
        expect(dio, isA<Dio>(),
            reason: 'Provider ${strategy.providerName} should create new Dio');
        expect(dio.options.baseUrl, equals('https://api.example.com'),
            reason:
                'Provider ${strategy.providerName} should use correct base URL');
      }
    });

    test('should apply provider-specific headers for all providers', () {
      final llmConfig = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      );

      // Test provider-specific header requirements
      final testCases = [
        {
          'strategy': AnthropicDioStrategy(),
          'config': AnthropicConfig.fromLLMConfig(llmConfig),
          'expectedHeaders': {
            'x-api-key': 'test-key',
            'anthropic-version': '2023-06-01'
          }
        },
        {
          'strategy': OpenAIDioStrategy(),
          'config': OpenAIConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'xAI'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'xai',
            providerName: 'xAI',
          ),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'Groq'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'groq',
            providerName: 'Groq',
          ),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'DeepSeek'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'deepseek',
            providerName: 'DeepSeek',
          ),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': OpenAIDioStrategy(providerName: 'Phind'),
          'config': OpenAICompatibleConfig.fromLLMConfig(
            llmConfig,
            providerId: 'phind',
            providerName: 'Phind',
          ),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': ElevenLabsDioStrategy(),
          'config': ElevenLabsConfig.fromLLMConfig(llmConfig),
          'expectedHeaders': {'xi-api-key': 'test-key'}
        },
      ];

      for (final testCase in testCases) {
        final strategy = testCase['strategy'] as ProviderDioStrategy;
        final config = testCase['config'];
        final expectedHeaders =
            testCase['expectedHeaders'] as Map<String, String>;

        final dio = DioClientFactory.create(
          strategy: strategy,
          config: config,
        );

        for (final entry in expectedHeaders.entries) {
          expect(dio.options.headers[entry.key], equals(entry.value),
              reason:
                  'Provider ${strategy.providerName} should have ${entry.key} header');
        }
      }
    });
  });
}

class _CapturingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{"ok": true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
