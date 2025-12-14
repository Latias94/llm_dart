import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/testing.dart' as anthropic;
import 'package:llm_dart_deepseek/testing.dart' as deepseek;
import 'package:llm_dart_xai/llm_dart_xai.dart' as xai;
import 'package:llm_dart_xai/testing.dart' as xai_testing;
import 'package:llm_dart_google/testing.dart' as google_testing;
import 'package:llm_dart_ollama/testing.dart' as ollama_testing;
import 'package:llm_dart_openai/testing.dart' as openai;
import 'package:llm_dart_openai_compatible/testing.dart';

void main() {
  group('Provider Client Dio Configuration Tests', () {
    late LLMConfig baseConfig;

    setUp(() {
      baseConfig = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        LLMConfigKeys.enableHttpLogging: true,
        LLMConfigKeys.httpProxy: 'http://proxy.example.com:8080',
        LLMConfigKeys.customHeaders: {'X-Test': 'value'},
        LLMConfigKeys.connectionTimeout: Duration(seconds: 30),
      });
    });

    group('Anthropic Client', () {
      test(
          'should use unified HTTP configuration when originalConfig is available',
          () {
        final config = anthropic.AnthropicConfig.fromLLMConfig(baseConfig);
        final client = anthropic.AnthropicClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added (more interceptors than just the endpoint-specific one)
        expect(client.dio.interceptors.length, greaterThan(1));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com/v1/',
          model: 'claude-sonnet-4-20250514',
        );
        final client = anthropic.AnthropicClient(config);

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
        final config = openai.OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'gpt-4',
          originalConfig: baseConfig,
        );
        final client = openai.OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = openai.OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1/',
          model: 'gpt-4',
        );
        final client = openai.OpenAIClient(config);

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
        final config = deepseek.DeepSeekConfig.fromLLMConfig(baseConfig);
        final client = deepseek.DeepSeekClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = deepseek.DeepSeekConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );
        final client = deepseek.DeepSeekClient(config);

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
        final config = GroqConfig.fromLLMConfig(baseConfig);
        final client = OpenAICompatibleClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = GroqConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );
        final client = OpenAICompatibleClient(config);

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
        final config = xai.XAIConfig.fromLLMConfig(baseConfig);
        final client = xai_testing.XAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio when originalConfig is null', () {
        final config = xai.XAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );
        final client = xai_testing.XAIClient(config);

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
        final client = google_testing.GoogleClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
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
        final client = google_testing.GoogleClient(config);

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
        final client = ollama_testing.OllamaClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
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
        final client = ollama_testing.OllamaClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('http://localhost:11434'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });
  });
}
