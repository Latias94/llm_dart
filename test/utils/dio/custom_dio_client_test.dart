import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai_compatible/client.dart';

void main() {
  group('Custom Dio Client Support Tests', () {
    group('Priority System Tests', () {
      test('should prioritize custom Dio over HTTP configuration', () {
        // Create custom Dio with specific settings
        final customDio = Dio();
        customDio.options.connectTimeout = Duration(seconds: 15);
        customDio.options.headers['X-Custom'] = 'custom-value';
        customDio.options.baseUrl = 'https://custom.example.com';

        // Create LLM config with HTTP settings that should be ignored
        final llmConfig = LLMConfig(
          baseUrl: 'https://should-be-ignored.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration(seconds: 60), // Should be ignored
        ).withTransportOptions({
          'customDio': customDio,
          'connectionTimeout': Duration(seconds: 30), // Should be ignored
          'customHeaders': {
            'X-Should-Be-Ignored': 'ignored'
          }, // Should be ignored
          'enableHttpLogging': true, // Should be ignored
        });

        // Test with Anthropic provider
        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Custom Dio should be used directly
        expect(anthropicClient.dio, equals(customDio));
        expect(anthropicClient.dio.options.connectTimeout,
            equals(Duration(seconds: 15)));
        expect(anthropicClient.dio.options.headers['X-Custom'],
            equals('custom-value'));

        // Base URL should be preserved from custom Dio
        expect(anthropicClient.dio.options.baseUrl,
            equals('https://custom.example.com'));
      });

      test('should fall back to HTTP configuration when no custom Dio', () {
        final llmConfig = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
          timeout: Duration(seconds: 45),
        ).withTransportOptions({
          'connectionTimeout': Duration(seconds: 30),
          'customHeaders': {'X-Test': 'test-value'},
          'enableHttpLogging': true,
        });

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Should use HTTP configuration
        expect(anthropicClient.dio.options.connectTimeout,
            equals(Duration(seconds: 30)));
        expect(anthropicClient.dio.options.headers['X-Test'],
            equals('test-value'));
        expect(anthropicClient.dio.options.baseUrl,
            equals('https://api.example.com/'));

        // Should have logging interceptor
        expect(anthropicClient.dio.interceptors.length, greaterThan(1));
      });

      test('should fall back to provider defaults when no configuration', () {
        final anthropicConfig = AnthropicConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com/v1/',
          model: 'claude-sonnet-4-20250514',
        );
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Should use provider defaults
        expect(anthropicClient.dio.options.baseUrl,
            equals('https://api.anthropic.com/v1/'));
        expect(anthropicClient.dio.options.connectTimeout,
            equals(Duration(seconds: 60))); // Default timeout

        // Should only have provider-specific interceptors (may have more than 1)
        expect(
            anthropicClient.dio.interceptors.length, greaterThanOrEqualTo(1));
      });
    });

    group('Provider-Specific Interceptor Tests', () {
      test('should add Anthropic-specific interceptors to custom Dio', () {
        final customDio = Dio();
        customDio.options.baseUrl = 'https://custom.anthropic.com';

        // Add a custom interceptor
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

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Should have both custom interceptor and Anthropic-specific interceptor(s)
        expect(
            anthropicClient.dio.interceptors.length, greaterThanOrEqualTo(2));
        expect(anthropicClient.dio, equals(customDio));
      });

      test(
          'should preserve custom interceptors while adding provider interceptors',
          () {
        final customDio = Dio();

        // Add multiple custom interceptors
        customDio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['X-Interceptor-1'] = 'active';
            handler.next(options);
          },
        ));

        customDio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['X-Interceptor-2'] = 'active';
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

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Should have 2 custom interceptors + Anthropic interceptor(s) >= 3 total
        expect(
            anthropicClient.dio.interceptors.length, greaterThanOrEqualTo(3));
      });
    });

    group('Base Configuration Application Tests', () {
      test('should apply base URL when custom Dio has empty base URL', () {
        final customDio = Dio();
        // Leave base URL empty
        expect(customDio.options.baseUrl, isEmpty);

        final llmConfig = LLMConfig(
          baseUrl: 'https://api.anthropic.com/v1/',
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        ).withTransportOptions({
          'customDio': customDio,
        });

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Base URL should be applied from config
        expect(anthropicClient.dio.options.baseUrl,
            equals('https://api.anthropic.com/v1/'));
      });

      test('should preserve custom Dio base URL when already set', () {
        final customDio = Dio();
        customDio.options.baseUrl = 'https://custom.anthropic.com/v2/';

        final llmConfig = LLMConfig(
          baseUrl: 'https://api.anthropic.com/v1/', // Should be ignored
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        ).withTransportOptions({
          'customDio': customDio,
        });

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Custom base URL should be preserved
        expect(anthropicClient.dio.options.baseUrl,
            equals('https://custom.anthropic.com/v2/'));
      });

      test('should merge essential headers without overriding custom headers',
          () {
        final customDio = Dio();
        customDio.options.headers['Authorization'] = 'Bearer custom-key';
        customDio.options.headers['X-Custom'] = 'custom-value';
        customDio.options.headers['Content-Type'] = 'application/custom';

        final llmConfig = LLMConfig(
          baseUrl: 'https://api.anthropic.com/v1/',
          apiKey: 'test-key', // Should not override custom Authorization
          model: 'claude-sonnet-4-20250514',
        ).withTransportOptions({
          'customDio': customDio,
        });

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Custom headers should be preserved (user's headers take precedence)
        expect(anthropicClient.dio.options.headers['Authorization'],
            equals('Bearer custom-key'));
        expect(anthropicClient.dio.options.headers['X-Custom'],
            equals('custom-value'));
        expect(anthropicClient.dio.options.headers['Content-Type'],
            equals('application/custom'));

        // Essential headers should be added only if not present
        // Since Authorization is already set, x-api-key should not be added
        expect(
            anthropicClient.dio.options.headers
                .containsKey('anthropic-version'),
            isTrue);
      });

      test('should add missing essential headers to custom Dio', () {
        final customDio = Dio();
        // Only set custom headers, no essential ones
        customDio.options.headers['X-Custom'] = 'custom-value';

        final llmConfig = LLMConfig(
          baseUrl: 'https://api.anthropic.com/v1/',
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        ).withTransportOptions({
          'customDio': customDio,
        });

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        // Should have both custom and essential headers
        expect(anthropicClient.dio.options.headers['X-Custom'],
            equals('custom-value'));
        // Essential headers are added via putIfAbsent, so they should be present
        // Anthropic uses x-api-key instead of Authorization
        expect(anthropicClient.dio.options.headers.containsKey('x-api-key'),
            isTrue);
        expect(anthropicClient.dio.options.headers.containsKey('Content-Type'),
            isTrue);
        expect(
            anthropicClient.dio.options.headers
                .containsKey('anthropic-version'),
            isTrue);
        expect(anthropicClient.dio.options.headers.length, greaterThan(1));
      });
    });

    group('Multi-Provider Tests', () {
      test('should work consistently across different providers', () {
        final customDio = Dio();
        customDio.options.connectTimeout = Duration(seconds: 20);
        customDio.options.headers['X-Multi-Provider'] = 'test';

        final llmConfig = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'customDio': customDio,
        });

        // Test with multiple providers
        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        final openaiConfig = OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1/',
          model: 'gpt-4',
          originalConfig: llmConfig,
        );
        final openaiClient = OpenAIClient(openaiConfig);

        final xaiConfig = OpenAICompatibleConfig.fromLLMConfig(
          llmConfig,
          providerId: 'xai',
          providerName: 'xAI',
        );
        final xaiClient = OpenAIClient(xaiConfig);

        // All should use the same custom Dio
        expect(anthropicClient.dio, equals(customDio));
        expect(openaiClient.dio, equals(customDio));
        expect(xaiClient.dio, equals(customDio));

        // All should have the custom timeout
        expect(anthropicClient.dio.options.connectTimeout,
            equals(Duration(seconds: 20)));
        expect(openaiClient.dio.options.connectTimeout,
            equals(Duration(seconds: 20)));
        expect(xaiClient.dio.options.connectTimeout,
            equals(Duration(seconds: 20)));

        // All should have the custom header
        expect(anthropicClient.dio.options.headers['X-Multi-Provider'],
            equals('test'));
        expect(openaiClient.dio.options.headers['X-Multi-Provider'],
            equals('test'));
        expect(
            xaiClient.dio.options.headers['X-Multi-Provider'], equals('test'));
      });

      test('should add provider-specific interceptors to same custom Dio', () {
        final customDio = Dio();
        final initialInterceptorCount = customDio.interceptors.length;

        final llmConfig = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'customDio': customDio,
        });

        // Create clients for different providers
        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);
        final anthropicClient = AnthropicClient(anthropicConfig);

        final openaiConfig = OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1/',
          model: 'gpt-4',
          originalConfig: llmConfig,
        );
        final openaiClient = OpenAIClient(openaiConfig);

        // Anthropic adds interceptors, OpenAI doesn't add provider-specific ones
        expect(
            anthropicClient.dio.interceptors.length,
            equals(
                initialInterceptorCount + 1)); // +1 for Anthropic interceptor
        expect(openaiClient.dio.interceptors.length,
            equals(initialInterceptorCount + 1)); // Same Dio instance
      });
    });

    group('Error Handling Tests', () {
      test('should handle null custom Dio gracefully', () {
        final llmConfig = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'customDio': null, // Explicitly null
        });

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

        // Should not throw and should fall back to HTTP configuration
        expect(() => AnthropicClient(anthropicConfig), returnsNormally);

        final anthropicClient = AnthropicClient(anthropicConfig);
        expect(anthropicClient.dio, isNotNull);
        expect(anthropicClient.dio.options.baseUrl,
            equals('https://api.example.com/'));
      });

      test('should handle custom Dio with unusual configuration', () {
        final customDio = Dio();
        // Set some unusual but valid configuration
        customDio.options.connectTimeout =
            Duration(milliseconds: 1); // Very short timeout

        final llmConfig = LLMConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'test-key',
          model: 'test-model',
        ).withTransportOptions({
          'customDio': customDio,
        });

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

        // Should not throw during client creation
        expect(() => AnthropicClient(anthropicConfig), returnsNormally);

        final anthropicClient = AnthropicClient(anthropicConfig);
        expect(anthropicClient.dio, equals(customDio));
        // Unusual configuration should be preserved (user's responsibility)
        expect(anthropicClient.dio.options.connectTimeout,
            equals(Duration(milliseconds: 1)));
      });
    });

    group('Integration Tests', () {
      test('should work with LLMBuilder fluent interface', () {
        final customDio = Dio();
        customDio.options.connectTimeout = Duration(seconds: 25);
        customDio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['X-Integration-Test'] = 'active';
            handler.next(options);
          },
        ));

        // Test with LLMBuilder
        final builder = LLMBuilder()
            .anthropic()
            .apiKey('test-key')
            .model('claude-sonnet-4-20250514')
            .http((http) => http.dioClient(customDio));

        expect(() => builder.build(), returnsNormally);
      });

      test('should preserve custom Dio across build operations', () {
        final customDio = Dio();
        customDio.options.headers['X-Persistent'] = 'value';

        final builder = LLMBuilder()
            .anthropic()
            .apiKey('test-key')
            .model('claude-sonnet-4-20250514')
            .http((http) => http.dioClient(customDio));

        // Build multiple times should not throw
        expect(() => builder.build(), returnsNormally);
        expect(() => builder.build(), returnsNormally);

        // Verify the custom Dio is still configured correctly
        expect(customDio.options.headers['X-Persistent'], equals('value'));
      });
    });
  });
}
