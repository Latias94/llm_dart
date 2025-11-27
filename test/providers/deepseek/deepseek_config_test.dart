import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart' as deepseek;

void main() {
  group('deepseek.DeepSeekConfig Tests', () {
    group('Basic Configuration', () {
      test('should create config with required parameters', () {
        const config = deepseek.DeepSeekConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.baseUrl, equals('https://api.deepseek.com/v1/'));
        expect(config.model, equals('deepseek-chat'));
      });

      test('should create config with all parameters', () {
        const config = deepseek.DeepSeekConfig(
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
      test('should detect reasoning support for reasoning models', () {
        const config = deepseek.DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-reasoner',
        );

        expect(config.supportsReasoning, isTrue);
      });

      test('should not support reasoning for non-reasoning models', () {
        const config = deepseek.DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-chat',
        );

        expect(config.supportsReasoning, isFalse);
      });

      test('should not support vision for any models', () {
        const chatConfig = deepseek.DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-chat',
        );

        const reasonerConfig = deepseek.DeepSeekConfig(
          apiKey: 'test-key',
          model: 'deepseek-reasoner',
        );

        expect(chatConfig.supportsVision, isFalse);
        expect(reasonerConfig.supportsVision, isFalse);
      });
    });

    group('Configuration Copying', () {
      test('should copy config with new values', () {
        const original = deepseek.DeepSeekConfig(
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
        const original = deepseek.DeepSeekConfig(
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
        const original = deepseek.DeepSeekConfig(
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

        final deepseekConfig = deepseek.DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.apiKey, equals('test-key'));
        expect(deepseekConfig.model, equals('deepseek-reasoner'));
        expect(deepseekConfig.temperature, equals(0.7));
        expect(deepseekConfig.maxTokens, equals(1500));
      });

      test('should extract DeepSeek-specific extensions', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          extensions: {
            'logprobs': true,
            'top_logprobs': 3,
            'frequency_penalty': 0.15,
            'presence_penalty': 0.25,
            'response_format': {'type': 'json_object'},
          },
        );

        final deepseekConfig = deepseek.DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.logprobs, isTrue);
        expect(deepseekConfig.topLogprobs, equals(3));
        expect(deepseekConfig.frequencyPenalty, equals(0.15));
        expect(deepseekConfig.presencePenalty, equals(0.25));
        expect(deepseekConfig.responseFormat, equals({'type': 'json_object'}));
      });

      test('should access extensions from original config', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
          extensions: {'customParam': 'customValue'},
        );

        final deepseekConfig = deepseek.DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.getExtension<String>('customParam'),
            equals('customValue'));
      });

      test('should handle missing extensions gracefully', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        );

        final deepseekConfig = deepseek.DeepSeekConfig.fromLLMConfig(llmConfig);

        expect(deepseekConfig.logprobs, isNull);
        expect(deepseekConfig.topLogprobs, isNull);
        expect(deepseekConfig.frequencyPenalty, isNull);
        expect(deepseekConfig.presencePenalty, isNull);
        expect(deepseekConfig.responseFormat, isNull);
      });
    });

    group('Default Values', () {
      test('should use correct default values', () {
        const config = deepseek.DeepSeekConfig(
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

        final config = deepseek.DeepSeekConfig(
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

        const original = deepseek.DeepSeekConfig(
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
