import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('DeepSeekConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = DeepSeekConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://api.deepseek.com/v1/'));
        expect(config.model, equals('deepseek-chat'));
      });

      test('should create config with all parameters', () {
        const config = DeepSeekConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.api.com',
          model: 'deepseek-reasoner',
          maxTokens: 2000,
          temperature: 0.8,
          systemPrompt: 'You are a helpful assistant',
          timeout: Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          logprobs: true,
          topLogprobs: 5,
          frequencyPenalty: 0.1,
          presencePenalty: 0.2,
          responseFormat: {'type': 'json_object'},
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://custom.api.com'));
        expect(config.model, equals('deepseek-reasoner'));
        expect(config.maxTokens, equals(2000));
        expect(config.temperature, equals(0.8));
        expect(config.systemPrompt, equals('You are a helpful assistant'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(50));
        expect(config.logprobs, isTrue);
        expect(config.topLogprobs, equals(5));
        expect(config.frequencyPenalty, equals(0.1));
        expect(config.presencePenalty, equals(0.2));
        expect(config.responseFormat, equals({'type': 'json_object'}));
      });
    });

    group('Model Support Detection', () {
      test('should not maintain a model capability matrix', () {
        final configs = [
          const DeepSeekConfig(apiKey: 'test-key', model: 'deepseek-chat'),
          const DeepSeekConfig(apiKey: 'test-key', model: 'deepseek-reasoner'),
          const DeepSeekConfig(apiKey: 'test-key', model: 'unknown-model'),
        ];

        for (final config in configs) {
          expect(config.supportsReasoning, isTrue);
          expect(config.supportsVision, isTrue);
          expect(config.supportsToolCalling, isTrue);
          expect(config.supportsCodeGeneration, isTrue);
        }
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = DeepSeekConfig(
          apiKey: 'original-key',
          model: 'deepseek-chat',
          temperature: 0.5,
        );

        final copied = original.copyWith(
          apiKey: 'new-key',
          temperature: 0.8,
        );

        expect(copied.apiKey, equals('new-key'));
        expect(copied.model, equals('deepseek-chat')); // Unchanged
        expect(copied.temperature, equals(0.8));
      });

      test('should preserve original values when not specified', () {
        const original = DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-reasoner',
          logprobs: true,
          topLogprobs: 5,
        );

        final copied = original.copyWith(temperature: 0.9);

        expect(copied.apiKey, equals('test-key'));
        expect(copied.model, equals('deepseek-reasoner'));
        expect(copied.logprobs, isTrue);
        expect(copied.topLogprobs, equals(5));
        expect(copied.temperature, equals(0.9));
      });

      test('should copy DeepSeek-specific parameters', () {
        const original = DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-chat',
          frequencyPenalty: 0.1,
          presencePenalty: 0.2,
        );

        final copied = original.copyWith(
          frequencyPenalty: 0.3,
          presencePenalty: 0.4,
        );

        expect(copied.frequencyPenalty, equals(0.3));
        expect(copied.presencePenalty, equals(0.4));
      });
    });

    group('LLMConfig Integration', () {
      test('should create from LLMConfig', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-reasoner',
          temperature: 0.7,
          maxTokens: 1500,
        );

        final deepseekConfig = DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.apiKey, equals('test-key'));
        expect(deepseekConfig.model, equals('deepseek-reasoner'));
        expect(deepseekConfig.temperature, equals(0.7));
        expect(deepseekConfig.maxTokens, equals(1500));
      });

      test('should extract DeepSeek-specific provider options', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          providerOptions: const {
            'deepseek': {
              'logprobs': true,
              'topLogprobs': 3,
              'frequencyPenalty': 0.15,
              'presencePenalty': 0.25,
              'responseFormat': {'type': 'json_object'},
            },
          },
        );

        final deepseekConfig = DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.logprobs, isTrue);
        expect(deepseekConfig.topLogprobs, equals(3));
        expect(deepseekConfig.frequencyPenalty, equals(0.15));
        expect(deepseekConfig.presencePenalty, equals(0.25));
        expect(deepseekConfig.responseFormat, equals({'type': 'json_object'}));
      });

      test('should preserve transportOptions via original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          transportOptions: const {
            'customHeaders': {'X-Test': 'customValue'},
          },
        );

        final deepseekConfig = DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.originalConfig, isNotNull);
        expect(
          deepseekConfig.originalConfig!
              .getTransportOption<Map<String, String>>('customHeaders'),
          equals({'X-Test': 'customValue'}),
        );
      });

      test('should handle missing provider options gracefully', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        final deepseekConfig = DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.logprobs, isNull);
        expect(deepseekConfig.topLogprobs, isNull);
        expect(deepseekConfig.frequencyPenalty, isNull);
        expect(deepseekConfig.presencePenalty, isNull);
        expect(deepseekConfig.responseFormat, isNull);
      });
    });

    group('Default Values', () {
      test('should use correct default values', () {
        const config = DeepSeekConfig(
          apiKey: 'test-key',
        );

        expect(config.baseUrl, equals('https://api.deepseek.com/v1/'));
        expect(config.model, equals('deepseek-chat'));
        expect(config.maxTokens, isNull);
        expect(config.temperature, isNull);
        expect(config.systemPrompt, isNull);
        expect(config.timeout, isNull);
        expect(config.topP, isNull);
        expect(config.topK, isNull);
        expect(config.logprobs, isNull);
        expect(config.topLogprobs, isNull);
        expect(config.frequencyPenalty, isNull);
        expect(config.presencePenalty, isNull);
        expect(config.responseFormat, isNull);
      });
    });

    group('Tool Configuration', () {
      test('should handle tool configuration', () {
        final tools = [
          Tool.function(
            name: 'test_function',
            description: 'A test function',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ];

        final config = DeepSeekConfig(
          apiKey: 'test-key',
          tools: tools,
          toolChoice: const AutoToolChoice(),
        );

        expect(config.tools, equals(tools));
        expect(config.toolChoice, isA<AutoToolChoice>());
      });

      test('should copy tool configuration', () {
        final tools = [
          Tool.function(
            name: 'test_function',
            description: 'A test function',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ];

        const original = DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-chat',
        );

        final copied = original.copyWith(
          tools: tools,
          toolChoice: const AnyToolChoice(),
        );

        expect(copied.tools, equals(tools));
        expect(copied.toolChoice, isA<AnyToolChoice>());
      });
    });
  });
}
