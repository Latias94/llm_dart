import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_anthropic/testing.dart'
    show AnthropicConfig, AnthropicDioStrategy;
import 'package:llm_dart_openai/testing.dart' as openai;
import 'package:llm_dart_deepseek/testing.dart'
    show DeepSeekConfig, DeepSeekDioStrategy;
import 'package:llm_dart_elevenlabs/testing.dart'
    show ElevenLabsConfig, ElevenLabsDioStrategy;
import 'package:llm_dart_google/testing.dart'
    show GoogleConfig, GoogleDioStrategy;
import 'package:llm_dart_groq/testing.dart' show GroqConfig, GroqDioStrategy;
import 'package:llm_dart_ollama/testing.dart'
    show OllamaConfig, OllamaDioStrategy;
import 'package:llm_dart_phind/testing.dart' show PhindConfig, PhindDioStrategy;
import 'package:llm_dart_xai/testing.dart' show XAIConfig, XAIDioStrategy;
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('DioClientFactory', () {
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

      // Should have Anthropic-specific interceptors
      expect(dio.interceptors.length, greaterThan(0));
    });

    test('should create Dio client with OpenAI strategy', () {
      final config = openai.OpenAIConfig(
        baseUrl: 'https://api.openai.com/v1/',
        apiKey: 'test-key',
        model: 'gpt-4',
      );

      final dio = DioClientFactory.create(
        strategy: openai.OpenAIDioStrategy(),
        config: config,
      );

      expect(dio, isA<Dio>());
      expect(dio.options.baseUrl, equals('https://api.openai.com/v1/'));
      expect(dio.options.headers['Authorization'], equals('Bearer test-key'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
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
      // Google uses query parameter auth, so no Authorization header
      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    });

    test('should use custom Dio when provided', () {
      final customDio = Dio();
      customDio.options.baseUrl = 'https://custom.example.com';
      customDio.options.headers['X-Custom'] = 'test';

      final llmConfig = LLMConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      ).withExtensions({
        LLMConfigKeys.customDio: customDio,
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
      ).withExtensions({
        LLMConfigKeys.customDio: customDio,
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
    });

    test('OpenAIDioStrategy should build correct headers', () {
      final config = openai.OpenAIConfig(
        baseUrl: 'https://api.openai.com/v1/',
        apiKey: 'test-key',
        model: 'gpt-4',
      );

      final strategy = openai.OpenAIDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
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
      // Google doesn't use Authorization header
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('XAIDioStrategy should build correct headers', () {
      final config = XAIConfig(
        baseUrl: 'https://api.x.ai/v1/',
        apiKey: 'test-key',
        model: 'grok-3',
      );

      final strategy = XAIDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
    });

    test('GroqDioStrategy should build correct headers', () {
      final config = GroqConfig(
        baseUrl: 'https://api.groq.com/openai/v1/',
        apiKey: 'test-key',
        model: 'llama-3.3-70b-versatile',
      );

      final strategy = GroqDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
    });

    test('DeepSeekDioStrategy should build correct headers', () {
      final config = DeepSeekConfig(
        baseUrl: 'https://api.deepseek.com/v1/',
        apiKey: 'test-key',
        model: 'deepseek-chat',
      );

      final strategy = DeepSeekDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
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
    });

    test('PhindDioStrategy should build correct headers', () {
      final config = PhindConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.phind.com/v1/',
        model: 'Phind-70B',
      );

      final strategy = PhindDioStrategy();
      final headers = strategy.buildHeaders(config);

      expect(headers['User-Agent'], equals(''));
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['Accept'], equals('*/*'));
      expect(headers['Accept-Encoding'], equals('Identity'));
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
      ).withExtensions({
        LLMConfigKeys.customDio: customDio,
      });

      // Test all provider strategies with custom Dio
      final providers = [
        {
          'strategy': AnthropicDioStrategy(),
          'config': AnthropicConfig.fromLLMConfig(llmConfig)
        },
        {
          'strategy': openai.OpenAIDioStrategy(),
          'config': openai.OpenAIConfig(
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
          'strategy': XAIDioStrategy(),
          'config': XAIConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': GroqDioStrategy(),
          'config': GroqConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': DeepSeekDioStrategy(),
          'config': DeepSeekConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
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
          'strategy': PhindDioStrategy(),
          'config': PhindConfig.fromLLMConfig(llmConfig)
        },
        {
          'strategy': ElevenLabsDioStrategy(),
          'config': ElevenLabsConfig.fromLLMConfig(llmConfig)
        },
      ];

      for (final provider in providers) {
        // Use dynamic to let generic inference pick the correct config type
        // for each provider-specific strategy.
        final strategy = provider['strategy'] as dynamic;
        final config = provider['config'] as ProviderHttpConfig;

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
          'strategy': openai.OpenAIDioStrategy(),
          'config': openai.OpenAIConfig(
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
          'strategy': XAIDioStrategy(),
          'config': XAIConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': GroqDioStrategy(),
          'config': GroqConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
        },
        {
          'strategy': DeepSeekDioStrategy(),
          'config': DeepSeekConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig)
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
          'strategy': PhindDioStrategy(),
          'config': PhindConfig.fromLLMConfig(llmConfig)
        },
        {
          'strategy': ElevenLabsDioStrategy(),
          'config': ElevenLabsConfig.fromLLMConfig(llmConfig)
        },
      ];

      for (final provider in providers) {
        final strategy = provider['strategy'] as dynamic;
        final config = provider['config'] as ProviderHttpConfig;

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
          'strategy': openai.OpenAIDioStrategy(),
          'config': openai.OpenAIConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': XAIDioStrategy(),
          'config': XAIConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': GroqDioStrategy(),
          'config': GroqConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': DeepSeekDioStrategy(),
          'config': DeepSeekConfig(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com',
              model: 'test-model',
              originalConfig: llmConfig),
          'expectedHeaders': {'Authorization': 'Bearer test-key'}
        },
        {
          'strategy': PhindDioStrategy(),
          'config': PhindConfig.fromLLMConfig(llmConfig),
          'expectedHeaders': {'User-Agent': '', 'Accept': '*/*'}
        },
        {
          'strategy': ElevenLabsDioStrategy(),
          'config': ElevenLabsConfig.fromLLMConfig(llmConfig),
          'expectedHeaders': {'xi-api-key': 'test-key'}
        },
      ];

      for (final testCase in testCases) {
        final strategy = testCase['strategy'] as dynamic;
        final config = testCase['config'] as ProviderHttpConfig;
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
