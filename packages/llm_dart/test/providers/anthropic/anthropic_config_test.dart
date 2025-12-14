import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/testing.dart' as anthropic;

void main() {
  group('anthropic.AnthropicConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://api.anthropic.com/v1/'));
        expect(config.model, equals('claude-sonnet-4-20250514'));
        expect(config.stream, isFalse);
        expect(config.reasoning, isFalse);
        expect(config.interleavedThinking, isFalse);
      });

      test('should create config with all parameters', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'claude-sonnet-4-20250514',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: Duration(seconds: 30),
          stream: true,
          topP: 0.9,
          topK: 50,
          reasoning: true,
          thinkingBudgetTokens: 5000,
          interleavedThinking: true,
          stopSequences: ['STOP'],
          user: 'test-user',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.model, equals('claude-sonnet-4-20250514'));
        expect(config.maxTokens, equals(2000));
        expect(config.temperature, equals(0.8));
        expect(config.systemPrompt, equals('You are a helpful assistant'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.stream, isTrue);
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(50));
        expect(config.reasoning, isTrue);
        expect(config.thinkingBudgetTokens, equals(5000));
        expect(config.interleavedThinking, isTrue);
        expect(config.stopSequences, equals(['STOP']));
        expect(config.user, equals('test-user'));
      });
    });

    group('Model Support Detection', () {
      test('should detect vision support for vision models', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-5-sonnet-20241022',
        );

        expect(config.supportsVision, isTrue);
      });

      test('should detect reasoning support for known reasoning models', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        );

        expect(config.supportsReasoning, isTrue);
      });

      test('should detect interleaved thinking support for Claude 4', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        );

        expect(config.supportsInterleavedThinking, isTrue);
      });

      test('should not support reasoning for unknown models by default', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-haiku-20240307',
        );

        expect(config.supportsReasoning, isFalse);
        expect(config.supportsInterleavedThinking, isFalse);
      });
    });

    group('Thinking Configuration Validation', () {
      test('should validate valid reasoning config', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
          reasoning: true,
          thinkingBudgetTokens: 5000,
        );

        expect(config.validateThinkingConfig(), isNull);
      });

      test('should allow reasoning for any model when explicitly enabled', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-haiku-20240307',
          reasoning: true,
        );

        // Validation is now permissive - trusts user configuration
        final error = config.validateThinkingConfig();
        expect(error, isNull);
      });

      test('should allow interleaved thinking when explicitly enabled', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-5-sonnet-20241022',
          interleavedThinking: true,
        );

        // Validation is now permissive - trusts user configuration
        final error = config.validateThinkingConfig();
        expect(error, isNull);
      });

      test('should reject excessive thinking budget', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
          reasoning: true,
          thinkingBudgetTokens: 50000, // Too high
        );

        final error = config.validateThinkingConfig();
        expect(error, isNotNull);
        expect(error, contains('exceeds maximum'));
      });

      test('should reject too small thinking budget', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
          reasoning: true,
          thinkingBudgetTokens: 500, // Too small
        );

        final error = config.validateThinkingConfig();
        expect(error, isNotNull);
        expect(error, contains('must be at least 1024'));
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = anthropic.AnthropicConfig(
          apiKey: 'original-key',
          model: 'claude-3-5-sonnet-20241022',
          temperature: 0.5,
        );

        final copied = original.copyWith(
          apiKey: 'new-key',
          temperature: 0.8,
        );

        expect(copied.apiKey, equals('new-key'));
        expect(copied.model, equals('claude-3-5-sonnet-20241022')); // Unchanged
        expect(copied.temperature, equals(0.8));
      });

      test('should preserve original values when not specified', () {
        const original = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
          reasoning: true,
          thinkingBudgetTokens: 5000,
        );

        final copied = original.copyWith(temperature: 0.9);

        expect(copied.apiKey, equals('test-key'));
        expect(copied.model, equals('claude-sonnet-4-20250514'));
        expect(copied.reasoning, isTrue);
        expect(copied.thinkingBudgetTokens, equals(5000));
        expect(copied.temperature, equals(0.9));
      });
    });

    group('LLMConfig Integration', () {
      test('should create from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-sonnet-4-20250514',
          temperature: 0.7,
          extensions: {
            LLMConfigKeys.reasoning: true,
            LLMConfigKeys.thinkingBudgetTokens: 3000,
            LLMConfigKeys.interleavedThinking: false,
          },
        );

        final anthropicConfig =
            anthropic.AnthropicConfig.fromLLMConfig(llmConfig);

        expect(anthropicConfig.apiKey, equals('test-key'));
        expect(anthropicConfig.model, equals('claude-sonnet-4-20250514'));
        expect(anthropicConfig.temperature, equals(0.7));
        expect(anthropicConfig.reasoning, isTrue);
        expect(anthropicConfig.thinkingBudgetTokens, equals(3000));
        expect(anthropicConfig.interleavedThinking, isFalse);
      });

      test('should access extensions from original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
          extensions: {'customParam': 'customValue'},
        );

        final anthropicConfig =
            anthropic.AnthropicConfig.fromLLMConfig(llmConfig);

        expect(anthropicConfig.getExtension<String>('customParam'),
            equals('customValue'));
      });

      test('should enable web search tool when webSearchConfig is set', () {
        final webSearch = WebSearchConfig.anthropic(
          maxUses: 3,
          allowedDomains: ['example.com'],
          blockedDomains: ['bad.com'],
          location: WebSearchLocation.newYork(),
        );

        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-sonnet-4-20250514',
          extensions: {
            LLMConfigKeys.webSearchEnabled: true,
            LLMConfigKeys.webSearchConfig: webSearch,
          },
        );

        final anthropicConfig =
            anthropic.AnthropicConfig.fromLLMConfig(llmConfig);
        final builder = anthropic.AnthropicRequestBuilder(anthropicConfig);

        final webSearchTool = Tool.function(
          name: 'web_search',
          description: 'Search the web',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'query': ParameterProperty(
                propertyType: 'string',
                description: 'The search query to execute',
              ),
            },
            required: const ['query'],
          ),
        );

        final converted = builder.convertTool(webSearchTool);

        expect(converted['type'], 'web_search_20250305');
        expect(converted['name'], 'web_search');
        expect(converted['max_uses'], 3);
        expect(converted['allowed_domains'], ['example.com']);
        expect(converted['blocked_domains'], ['bad.com']);
        expect(converted['user_location'], isA<Map<String, dynamic>>());
        expect(converted['user_location']['city'], 'New York');
      });
    });

    group('Thinking Budget Limits', () {
      test('should return correct max thinking budget for reasoning models',
          () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        );

        expect(config.maxThinkingBudgetTokens, equals(32000));
      });

      test('should return zero for non-reasoning models', () {
        const config = anthropic.AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-haiku-20240307',
        );

        expect(config.maxThinkingBudgetTokens, equals(0));
      });
    });
  });
}
