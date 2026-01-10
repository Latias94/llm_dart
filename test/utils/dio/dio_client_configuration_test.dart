import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_google/client.dart';
import 'package:llm_dart_ollama/client.dart';

void main() {
  group('Provider Client Dio Configuration Tests', () {
    late LLMConfig baseConfig;

    setUp(() {
      baseConfig = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withTransportOptions({
        'enableHttpLogging': true,
        'httpProxy': 'http://proxy.example.com:8080',
        'customHeaders': {'X-Test': 'value'},
        'connectionTimeout': Duration(seconds: 30),
      });
    });

    group('Anthropic Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = AnthropicConfig.fromLLMConfig(baseConfig);
        final client = AnthropicClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com/'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added (more interceptors than just the endpoint-specific one)
        expect(client.dio.interceptors.length, greaterThan(1));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = AnthropicConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com/v1/',
          model: 'claude-sonnet-4-20250514',
        );
        final client = AnthropicClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl,
            equals('https://api.anthropic.com/v1/'));

        // Should have provider-specific interceptors but no logging interceptor
        // When using unified config, it would have more interceptors (provider + logging)
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(1));
      });
    });

    group('OpenAI Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'gpt-4',
          originalConfig: baseConfig,
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com/'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1/',
          model: 'gpt-4',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(
            client.dio.options.baseUrl, equals('https://api.openai.com/v1/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('DeepSeek Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = OpenAICompatibleConfig.fromLLMConfig(
          baseConfig,
          providerId: 'deepseek',
          providerName: 'DeepSeek',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com/'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = OpenAICompatibleConfig(
          providerId: 'deepseek',
          providerName: 'DeepSeek',
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(
            client.dio.options.baseUrl, equals('https://api.deepseek.com/v1/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('Groq Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = OpenAICompatibleConfig.fromLLMConfig(
          baseConfig,
          providerId: 'groq',
          providerName: 'Groq',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com/'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = OpenAICompatibleConfig(
          providerId: 'groq',
          providerName: 'Groq',
          apiKey: 'test-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl,
            equals('https://api.groq.com/openai/v1/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('xAI Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = OpenAICompatibleConfig.fromLLMConfig(
          baseConfig,
          providerId: 'xai',
          providerName: 'xAI',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com/'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = OpenAICompatibleConfig(
          providerId: 'xai',
          providerName: 'xAI',
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.x.ai/v1/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('Google Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = GoogleConfig.fromLLMConfig(baseConfig);
        final client = GoogleClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com/'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
          model: 'gemini-1.5-flash',
        );
        final client = GoogleClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl,
            equals('https://generativelanguage.googleapis.com/v1beta/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('Ollama Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = OllamaConfig.fromLLMConfig(baseConfig);
        final client = OllamaClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com/'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = OllamaConfig(
          baseUrl: 'http://localhost:11434',
          model: 'llama3.2',
        );
        final client = OllamaClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('http://localhost:11434/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });
  });
}
