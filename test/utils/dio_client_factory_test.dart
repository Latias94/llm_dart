import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/providers/anthropic/config.dart';
import 'package:llm_dart/providers/anthropic/dio_strategy.dart';
import 'package:llm_dart/providers/openai/config.dart';
import 'package:llm_dart/providers/openai/dio_strategy.dart';
import 'package:llm_dart/providers/google/config.dart';
import 'package:llm_dart/providers/google/dio_strategy.dart';
import 'package:llm_dart/providers/xai/config.dart';
import 'package:llm_dart/providers/xai/dio_strategy.dart';
import 'package:llm_dart/providers/groq/config.dart';
import 'package:llm_dart/providers/groq/dio_strategy.dart';
import 'package:llm_dart/providers/deepseek/config.dart';
import 'package:llm_dart/providers/deepseek/dio_strategy.dart';
import 'package:llm_dart/providers/ollama/config.dart';
import 'package:llm_dart/providers/ollama/dio_strategy.dart';
import 'package:llm_dart/providers/phind/config.dart';
import 'package:llm_dart/providers/phind/dio_strategy.dart';
import 'package:llm_dart/providers/elevenlabs/config.dart';
import 'package:llm_dart/providers/elevenlabs/dio_strategy.dart';
import 'package:llm_dart/utils/dio_client_factory.dart';

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
        model: 'grok-2-latest',
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
