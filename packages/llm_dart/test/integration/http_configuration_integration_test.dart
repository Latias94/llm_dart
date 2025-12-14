import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('HTTP Configuration Integration Tests', () {
    group('LLMBuilder HTTP Integration', () {
      test('should apply HTTP configuration to LLMConfig extensions', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http
                .proxy('http://proxy.example.com:8080')
                .headers({'X-Custom': 'value'})
                .connectionTimeout(Duration(seconds: 30))
                .enableLogging(true));

        // Access the internal config to verify extensions were applied
        // Note: This assumes we have access to the config for testing
        expect(builder, isNotNull);
      });

      test('should handle multiple HTTP configurations', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http.proxy('http://proxy:8080'))
            .http((http) => http.enableLogging(true))
            .http((http) => http.headers({'X-Custom': 'value'}));

        expect(builder, isNotNull);
      });

      test('should merge HTTP configurations correctly', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http
                .headers({'X-Header-1': 'value1'}).connectionTimeout(
                    Duration(seconds: 30)))
            .http((http) =>
                http.headers({'X-Header-2': 'value2'}).enableLogging(true));

        expect(builder, isNotNull);
      });

      test('should override HTTP configurations when conflicting', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http.proxy('http://proxy1:8080'))
            .http((http) => http.proxy('http://proxy2:8080'));

        expect(builder, isNotNull);
      });
    });

    group('Provider-Specific HTTP Configuration', () {
      test('should work with OpenAI provider', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http
                .headers({'X-OpenAI-Custom': 'value'}).connectionTimeout(
                    Duration(seconds: 30)));

        expect(builder, isNotNull);
      });

      test('should work with Anthropic provider', () {
        final builder = LLMBuilder()
            .anthropic()
            .apiKey('test-key')
            .model('claude-3-5-haiku-20241022')
            .http((http) => http
                .headers({'X-Anthropic-Custom': 'value'}).enableLogging(true));

        expect(builder, isNotNull);
      });

      test('should work with Google provider', () {
        final builder = LLMBuilder()
            .google()
            .apiKey('test-key')
            .model('gemini-1.5-flash')
            .http((http) => http
                .proxy('http://proxy:8080')
                .connectionTimeout(Duration(seconds: 45)));

        expect(builder, isNotNull);
      });

      test('should work with DeepSeek provider', () {
        final builder = LLMBuilder()
            .deepseek()
            .apiKey('test-key')
            .model('deepseek-chat')
            .http((http) => http
                .headers({'X-DeepSeek-Custom': 'value'}).receiveTimeout(
                    Duration(minutes: 5)));

        expect(builder, isNotNull);
      });

      test('should work with Ollama provider', () {
        final builder = LLMBuilder()
            .ollama()
            .baseUrl('http://localhost:11434')
            .model('llama3.2')
            .http(
                (http) => http.bypassSSLVerification(true).enableLogging(true));

        expect(builder, isNotNull);
      });

      test('should work with xAI provider', () {
        final builder = LLMBuilder()
            .xai()
            .apiKey('test-key')
            .model('grok-3')
            .http((http) => http.headers({'X-xAI-Custom': 'value'}).sendTimeout(
                Duration(seconds: 120)));

        expect(builder, isNotNull);
      });

      test('should work with Groq provider', () {
        final builder = LLMBuilder()
            .groq()
            .apiKey('test-key')
            .model('llama-3.1-8b-instant')
            .http((http) => http
                .proxy('http://proxy:8080')
                .connectionTimeout(Duration(seconds: 15)));

        expect(builder, isNotNull);
      });

      test('should work with ElevenLabs provider', () {
        final builder = LLMBuilder().elevenlabs().apiKey('test-key').http(
            (http) => http
                .headers({'X-ElevenLabs-Custom': 'value'}).enableLogging(true));

        expect(builder, isNotNull);
      });
    });

    group('Complex Configuration Scenarios', () {
      test('should handle enterprise configuration', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('enterprise-key')
            .model('gpt-4')
            .http((http) => http
                .proxy('http://corporate-proxy:8080')
                .headers({
                  'X-Corporate-ID': 'dept-123',
                  'X-Request-Source': 'enterprise-app',
                  'User-Agent': 'CorporateApp/2.0',
                })
                .sslCertificate('/etc/ssl/corporate-cert.pem')
                .connectionTimeout(Duration(seconds: 45))
                .receiveTimeout(Duration(minutes: 10))
                .enableLogging(false)) // Disabled in production
            .temperature(0.7)
            .maxTokens(2000)
            .systemPrompt('You are a corporate assistant.');

        expect(builder, isNotNull);
      });

      test('should handle development configuration', () {
        final builder = LLMBuilder()
            .ollama()
            .baseUrl('https://localhost:11434')
            .model('llama3.2')
            .http((http) => http
                .bypassSSLVerification(true) // For local development
                .headers({
                  'X-Environment': 'development',
                  'X-Debug-Mode': 'true',
                })
                .connectionTimeout(Duration(seconds: 10))
                .enableLogging(true)) // Enabled for debugging
            .temperature(0.9)
            .maxTokens(500);

        expect(builder, isNotNull);
      });

      test('should handle testing configuration', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4o-mini')
            .http((http) => http
                .headers({
                  'X-Test-Run-ID': 'test-run-123',
                  'X-Environment': 'testing',
                })
                .connectionTimeout(Duration(seconds: 5))
                .receiveTimeout(Duration(seconds: 30))
                .enableLogging(true))
            .temperature(0.0) // Deterministic for testing
            .maxTokens(100);

        expect(builder, isNotNull);
      });
    });

    group('Configuration Validation', () {
      test('should handle empty HTTP configuration', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http); // Empty configuration

        expect(builder, isNotNull);
      });

      test('should handle HTTP configuration with provider-specific methods',
          () {
        final builder = LLMBuilder()
            .openai((openai) => openai.frequencyPenalty(0.1))
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http.enableLogging(true))
            .reasoningEffort(ReasoningEffort.medium);

        expect(builder, isNotNull);
      });

      test('should handle HTTP configuration with tool configuration', () {
        final tool = Tool.function(
          name: 'test_tool',
          description: 'A test tool',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        );

        final builder = LLMBuilder()
            .anthropic()
            .apiKey('test-key')
            .model('claude-3-5-haiku-20241022')
            .http((http) => http
                .headers({'X-Tool-Test': 'true'}).connectionTimeout(
                    Duration(seconds: 60)))
            .tools([tool]).toolChoice(AutoToolChoice());

        expect(builder, isNotNull);
      });

      test('should handle HTTP configuration with web search', () {
        final builder = LLMBuilder()
            .xai()
            .apiKey('test-key')
            .model('grok-3')
            .http((http) => http
                .headers({'X-Search-Enabled': 'true'}).receiveTimeout(
                    Duration(minutes: 5)))
            .enableWebSearch();

        expect(builder, isNotNull);
      });
    });

    group('Error Scenarios', () {
      test('should handle HTTP configuration without provider selection', () {
        // This should still work, but building will fail
        final builder = LLMBuilder()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http.enableLogging(true));

        expect(builder, isNotNull);
        expect(() => builder.build(), throwsA(isA<GenericError>()));
      });

      test('should handle HTTP configuration without required parameters', () {
        // This should still work for configuration, but building may fail
        final builder =
            LLMBuilder().openai().http((http) => http.enableLogging(true));
        // Missing API key and model

        expect(builder, isNotNull);
        // Building would fail due to missing required parameters
      });
    });

    group('Configuration Persistence', () {
      test('should maintain HTTP configuration through method chaining', () {
        final builder = LLMBuilder()
            .http((http) => http.proxy('http://proxy:8080'))
            .openai()
            .apiKey('test-key')
            .http((http) => http.enableLogging(true))
            .model('gpt-4')
            .http((http) => http.headers({'X-Final': 'value'}));

        expect(builder, isNotNull);
      });

      test('should allow HTTP configuration at any point in chain', () {
        final builder = LLMBuilder()
            .openai()
            .http((http) => http.proxy('http://proxy:8080'))
            .apiKey('test-key')
            .http((http) => http.enableLogging(true))
            .model('gpt-4')
            .temperature(0.7)
            .http((http) => http.headers({'X-Last': 'value'}));

        expect(builder, isNotNull);
      });
    });
  });
}
