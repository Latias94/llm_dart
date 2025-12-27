import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('AnthropicConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = AnthropicConfig(
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
        const config = AnthropicConfig(
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
      test('does not maintain per-model capability matrices', () {
        const config = AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-haiku-20240307',
        );

        expect(config.supportsVision, isTrue);
        expect(config.supportsToolCalling, isTrue);
        expect(config.supportsReasoning, isTrue);
        expect(config.supportsInterleavedThinking, isTrue);
        expect(config.supportsPDF, isTrue);
      });
    });

    group('Thinking Configuration Validation', () {
      test('should validate valid reasoning config', () {
        const config = AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
          reasoning: true,
          thinkingBudgetTokens: 5000,
        );

        expect(config.validateThinkingConfig(), isNull);
      });

      test('does not enforce thinking budget constraints', () {
        const config = AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-haiku-20240307',
          reasoning: true,
          thinkingBudgetTokens: 500, // would have been rejected previously
        );

        expect(config.validateThinkingConfig(), isNull);
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = AnthropicConfig(
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
        const original = AnthropicConfig(
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
          providerOptions: const {
            'anthropic': {
              'reasoning': true,
              'thinkingBudgetTokens': 3000,
              'interleavedThinking': false,
            },
          },
        );

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

        expect(anthropicConfig.apiKey, equals('test-key'));
        expect(anthropicConfig.model, equals('claude-sonnet-4-20250514'));
        expect(anthropicConfig.temperature, equals(0.7));
        expect(anthropicConfig.reasoning, isTrue);
        expect(anthropicConfig.thinkingBudgetTokens, equals(3000));
        expect(anthropicConfig.interleavedThinking, isFalse);
      });

      test('should read cacheControl from providerOptions', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-sonnet-4-20250514',
          providerOptions: const {
            'anthropic': {
              'cacheControl': {'type': 'ephemeral', 'ttl': '1h'},
            },
          },
        );

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

        expect(
          anthropicConfig.cacheControl,
          equals({'type': 'ephemeral', 'ttl': '1h'}),
        );
      });

      test('should read extraBody/extraHeaders from providerOptions', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-sonnet-4-20250514',
          providerOptions: const {
            'anthropic': {
              'extraBody': {'foo': 'bar'},
              'extraHeaders': {'x-test': '1'},
            },
          },
        );

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

        expect(anthropicConfig.extraBody, equals({'foo': 'bar'}));
        expect(anthropicConfig.extraHeaders, equals({'x-test': '1'}));
      });

      test('should preserve transportOptions via original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.anthropic.com',
          model: 'claude-3-5-sonnet-20241022',
          transportOptions: const {
            'customHeaders': {'X-Test': 'customValue'},
          },
        );

        final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

        expect(anthropicConfig.originalConfig, isNotNull);
        expect(
          anthropicConfig.originalConfig!
              .getTransportOption<Map<String, String>>('customHeaders'),
          equals({'X-Test': 'customValue'}),
        );
      });
    });

    group('Thinking Budget Limits', () {
      test('should return correct max thinking budget for reasoning models',
          () {
        const config = AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        );

        expect(config.maxThinkingBudgetTokens, equals(32000));
      });

      test('does not vary max thinking budget by model', () {
        const config = AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-3-haiku-20240307',
        );

        expect(config.maxThinkingBudgetTokens, equals(32000));
      });
    });
  });
}
