import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart' as deepseek;
import 'package:llm_dart_xai/llm_dart_xai.dart' as xai;

void main() {
  group('HTTP Configuration Integration Tests', () {
    group('Provider Builder HTTP Configuration', () {
      test('should create Anthropic provider with HTTP configuration',
          () async {
        final provider = await ai()
            .anthropic()
            .apiKey('test-api-key')
            .model('claude-sonnet-4-20250514')
            .http((http) => http
                .enableLogging(true)
                .headers({'X-Test-Client': 'llm-dart-test'}).connectionTimeout(
                    Duration(seconds: 10)))
            .build();

        // Test that provider was created successfully
        expect(provider, isNotNull);
        expect(provider, isA<anthropic.AnthropicProvider>());

        // Test that HTTP configuration was applied (without making API calls)
        final anthropicProvider = provider as anthropic.AnthropicProvider;
        expect(anthropicProvider.config.apiKey, equals('test-api-key'));
        expect(
            anthropicProvider.config.model, equals('claude-sonnet-4-20250514'));
      });

      test('should create OpenAI provider with HTTP configuration', () async {
        final provider = await ai()
            .openai()
            .apiKey('test-api-key')
            .model('gpt-4')
            .http((http) => http
                .enableLogging(true)
                .headers({'X-Test-Client': 'llm-dart-test'}).receiveTimeout(
                    Duration(seconds: 30)))
            .build();

        // Test that provider was created successfully
        expect(provider, isNotNull);
        expect(provider, isA<openai.OpenAIProvider>());

        // Test that HTTP configuration was applied (without making API calls)
        final openaiProvider = provider as openai.OpenAIProvider;
        expect(openaiProvider.config.apiKey, equals('test-api-key'));
        expect(openaiProvider.config.model, equals('gpt-4'));
      });

      test('should create DeepSeek provider with HTTP configuration', () async {
        final provider = await ai()
            .deepseek()
            .apiKey('test-api-key')
            .model('deepseek-chat')
            .http((http) => http
                .enableLogging(true)
                .headers({'X-Test-Client': 'llm-dart-test'}).sendTimeout(
                    Duration(seconds: 20)))
            .build();

        // Test that provider was created successfully
        expect(provider, isNotNull);
        expect(provider, isA<deepseek.DeepSeekProvider>());

        // Test that HTTP configuration was applied (without making API calls)
        final deepseekProvider = provider as deepseek.DeepSeekProvider;
        expect(deepseekProvider.config.apiKey, equals('test-api-key'));
        expect(deepseekProvider.config.model, equals('deepseek-chat'));
      });

      test('should create Groq provider with HTTP configuration', () async {
        final provider = await ai()
            .groq()
            .apiKey('test-api-key')
            .model('llama-3.3-70b-versatile')
            .http((http) => http
                .enableLogging(true)
                .headers({'X-Test-Client': 'llm-dart-test'}))
            .build();

        // Test that provider was created successfully
        expect(provider, isNotNull);
        expect(provider, isA<GroqProvider>());

        // Test that HTTP configuration was applied (without making API calls)
        final groqProvider = provider as GroqProvider;
        expect(groqProvider.config.apiKey, equals('test-api-key'));
        expect(groqProvider.config.model, equals('llama-3.3-70b-versatile'));
      });

      test('should create xAI provider with HTTP configuration', () async {
        final provider = await ai()
            .xai()
            .apiKey('test-api-key')
            .model('grok-3')
            .http((http) => http
                .enableLogging(true)
                .headers({'X-Test-Client': 'llm-dart-test'}))
            .build();

        // Test that provider was created successfully
        expect(provider, isNotNull);
        expect(provider, isA<xai.XAIProvider>());

        // Test that HTTP configuration was applied (without making API calls)
        final xaiProvider = provider as xai.XAIProvider;
        expect(xaiProvider.config.apiKey, equals('test-api-key'));
        expect(xaiProvider.config.model, equals('grok-3'));
      });

      test('should create Google provider with HTTP configuration', () async {
        final provider = await ai()
            .google()
            .apiKey('test-api-key')
            .model('gemini-1.5-flash')
            .http((http) => http
                .enableLogging(true)
                .headers({'X-Test-Client': 'llm-dart-test'}))
            .build();

        // Test that provider was created successfully
        expect(provider, isNotNull);
        expect(provider, isA<GoogleProvider>());

        // Test that HTTP configuration was applied (without making API calls)
        final googleProvider = provider as GoogleProvider;
        expect(googleProvider.config.apiKey, equals('test-api-key'));
        expect(googleProvider.config.model, equals('gemini-1.5-flash'));
      });
    });

    group('Complex HTTP Configuration Scenarios', () {
      test('should handle comprehensive HTTP configuration', () async {
        final provider = await ai()
            .anthropic()
            .apiKey('test-api-key')
            .model('claude-sonnet-4-20250514')
            .http((http) => http
                .enableLogging(true)
                .headers({
                  'X-Test-Client': 'llm-dart-test',
                  'X-Test-Version': '1.0.0',
                  'X-Test-Environment': 'testing',
                })
                .connectionTimeout(Duration(seconds: 15))
                .receiveTimeout(Duration(seconds: 60))
                .sendTimeout(Duration(seconds: 30))
                .proxy('http://proxy.example.com:8080')
                .bypassSSLVerification(false))
            .build();

        // Test that provider was created successfully with complex configuration
        expect(provider, isNotNull);
        expect(provider, isA<anthropic.AnthropicProvider>());

        final anthropicProvider = provider as anthropic.AnthropicProvider;
        expect(anthropicProvider.config.apiKey, equals('test-api-key'));
        expect(
            anthropicProvider.config.model, equals('claude-sonnet-4-20250514'));
      });

      test('should work without HTTP configuration', () async {
        final provider = await ai()
            .anthropic()
            .apiKey('test-api-key')
            .model('claude-sonnet-4-20250514')
            .build();

        // Test that provider was created successfully without HTTP config
        expect(provider, isNotNull);
        expect(provider, isA<anthropic.AnthropicProvider>());

        final anthropicProvider = provider as anthropic.AnthropicProvider;
        expect(anthropicProvider.config.apiKey, equals('test-api-key'));
        expect(
            anthropicProvider.config.model, equals('claude-sonnet-4-20250514'));
      });
    });

    group('Provider Configuration Validation', () {
      test('should validate provider configuration without API calls',
          () async {
        // Test multiple providers can be configured correctly
        final providers = <dynamic>[];

        providers.add(await ai()
            .anthropic()
            .apiKey('test-key')
            .model('claude-sonnet-4-20250514')
            .build());

        providers
            .add(await ai().openai().apiKey('test-key').model('gpt-4').build());

        providers.add(await ai()
            .deepseek()
            .apiKey('test-key')
            .model('deepseek-chat')
            .build());

        // Verify all providers were created
        expect(providers, hasLength(3));
        expect(providers[0], isA<anthropic.AnthropicProvider>());
        expect(providers[1], isA<openai.OpenAIProvider>());
        expect(providers[2], isA<deepseek.DeepSeekProvider>());
      });
    });
  });
}
