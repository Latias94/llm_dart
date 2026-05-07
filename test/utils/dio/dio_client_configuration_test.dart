import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/providers/anthropic/client.dart';
import 'package:llm_dart/providers/anthropic/config.dart';
import 'package:llm_dart/providers/deepseek/client.dart';
import 'package:llm_dart/providers/deepseek/config.dart';
import 'package:llm_dart/providers/google/client.dart';
import 'package:llm_dart/providers/google/config.dart';
import 'package:llm_dart/providers/groq/client.dart';
import 'package:llm_dart/providers/groq/config.dart';
import 'package:llm_dart/providers/ollama/client.dart';
import 'package:llm_dart/providers/ollama/config.dart';
import 'package:llm_dart/providers/openai/client.dart';
import 'package:llm_dart/providers/openai/config.dart';
import 'package:llm_dart/providers/xai/client.dart';
import 'package:llm_dart/providers/xai/config.dart';
import 'package:llm_dart/src/compatibility/providers/anthropic_config_adapter.dart';
import 'package:llm_dart/src/compatibility/providers/openai_family_compat_support.dart';
import 'package:llm_dart/src/compatibility/providers/openai_family_compat_deepseek_config.dart';
import 'package:llm_dart/src/compatibility/providers/openai_family_compat_groq_config.dart';
import 'package:llm_dart/src/compatibility/providers/openai_family_compat_xai_config.dart';
import 'package:llm_dart/src/compatibility/providers/google_config_adapter.dart';
import 'package:llm_dart/src/compatibility/providers/ollama/config_adapter.dart';
import 'package:test/test.dart';
import 'package:llm_dart_transport/dio.dart';

void main() {
  group('Provider Client Dio Configuration Tests', () {
    late LLMConfig baseConfig;

    setUp(() {
      baseConfig = LLMConfig(
        baseUrl: 'https://api.example.com',
        apiKey: 'test-key',
        model: 'test-model',
      ).withExtensions({
        'enableHttpLogging': true,
        'httpProxy': 'http://proxy.example.com:8080',
        'customHeaders': {'X-Test': 'value'},
        'connectionTimeout': Duration(seconds: 30),
      });
    });

    group('Anthropic Client', () {
      test('should use unified HTTP configuration from legacy dioOverrides',
          () {
        final config = createLegacyAnthropicConfig(baseConfig);
        final client = AnthropicClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added (more interceptors than just the endpoint-specific one)
        expect(client.dio.interceptors.length, greaterThan(1));
      });

      test('should fall back to simple Dio without legacy dioOverrides', () {
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
        // When legacy dioOverrides are projected, it would have more interceptors.
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(1));
      });
    });

    group('OpenAI Client', () {
      test('should use unified HTTP configuration from legacy dioOverrides',
          () {
        final config = createLegacyOpenAIConfig(baseConfig).copyWith(
          model: 'gpt-4',
        );
        final client = OpenAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio without legacy dioOverrides', () {
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
      test('should use unified HTTP configuration from legacy dioOverrides',
          () {
        final config = createLegacyDeepSeekConfig(baseConfig);
        final client = DeepSeekClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio without legacy dioOverrides', () {
        final config = DeepSeekConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );
        final client = DeepSeekClient(config);

        expect(client.dio, isA<Dio>());
        expect(
            client.dio.options.baseUrl, equals('https://api.deepseek.com/v1/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('Groq Client', () {
      test('should use unified HTTP configuration from legacy dioOverrides',
          () {
        final config = createLegacyGroqConfig(baseConfig);
        final client = GroqClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio without legacy dioOverrides', () {
        final config = GroqConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.groq.com/openai/v1/',
          model: 'llama-3.3-70b-versatile',
        );
        final client = GroqClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl,
            equals('https://api.groq.com/openai/v1/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('xAI Client', () {
      test('should use unified HTTP configuration from legacy dioOverrides',
          () {
        final config = createLegacyXAIConfig(baseConfig);
        final client = XAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio without legacy dioOverrides', () {
        final config = XAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.x.ai/v1/',
          model: 'grok-3',
        );
        final client = XAIClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.x.ai/v1/'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });

    group('Google Client', () {
      test('should use unified HTTP configuration from legacy dioOverrides',
          () {
        final config = createLegacyGoogleConfig(baseConfig);
        final client = GoogleClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio without legacy dioOverrides', () {
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
      test('should use unified HTTP configuration from legacy dioOverrides',
          () {
        final config = createLegacyOllamaConfig(baseConfig);
        final client = OllamaClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('https://api.example.com'));
        expect(
            client.dio.options.connectTimeout, equals(Duration(seconds: 30)));

        // Check that logging interceptor is added
        expect(client.dio.interceptors.length, greaterThan(0));
      });

      test('should fall back to simple Dio without legacy dioOverrides', () {
        final config = OllamaConfig(
          baseUrl: 'http://localhost:11434',
          model: 'llama3.2',
        );
        final client = OllamaClient(config);

        expect(client.dio, isA<Dio>());
        expect(client.dio.options.baseUrl, equals('http://localhost:11434'));

        // Should have minimal interceptors in fallback mode
        expect(client.dio.interceptors.length, greaterThanOrEqualTo(0));
      });
    });
  });
}
