import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Groq Tool Calling Tests', () {
    test('should support tool calling for supported models', () {
      final supportedModels = [
        'llama-4-scout-17b-16e-instruct',
        'llama-4-maverick-17b-128e-instruct',
        'qwen-qwq-32b',
        'deepseek-r1-distill-qwen-32b',
        'deepseek-r1-distill-llama-70b',
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'gemma2-9b-it',
      ];

      for (final model in supportedModels) {
        final config = GroqConfig(
          apiKey: 'test-key',
          model: model,
        );
        expect(config.supportsToolCalling, isTrue,
            reason: 'Model $model should support tool calling');
      }
    });

    test('should not support tool calling for unsupported models', () {
      final unsupportedModels = [
        'llama-3-8b-base',
        'mixtral-8x7b-base',
        'unknown-model',
      ];

      for (final model in unsupportedModels) {
        final config = GroqConfig(
          apiKey: 'test-key',
          model: model,
        );
        expect(config.supportsToolCalling, isFalse,
            reason: 'Model $model should not support tool calling');
      }
    });

    test('should support parallel tool calling for most models', () {
      final parallelSupportedModels = [
        'llama-4-scout-17b-16e-instruct',
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'qwen-qwq-32b',
      ];

      for (final model in parallelSupportedModels) {
        final config = GroqConfig(
          apiKey: 'test-key',
          model: model,
        );
        expect(config.supportsParallelToolCalling, isTrue,
            reason: 'Model $model should support parallel tool calling');
      }
    });

    test('should not support parallel tool calling for gemma2-9b-it', () {
      final config = GroqConfig(
        apiKey: 'test-key',
        model: 'gemma2-9b-it',
      );
      expect(config.supportsToolCalling, isTrue,
          reason: 'gemma2-9b-it should support tool calling');
      expect(config.supportsParallelToolCalling, isFalse,
          reason: 'gemma2-9b-it should not support parallel tool calling');
    });

    test('should create config with tools and tool choice', () {
      final config = GroqConfig(
        apiKey: 'test-key',
        model: 'llama-3.3-70b-versatile',
        tools: [
          Tool.function(
            name: 'get_weather',
            description: 'Get weather information',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'location': ParameterProperty(
                  propertyType: 'string',
                  description: 'City name',
                ),
              },
              required: ['location'],
            ),
          ),
        ],
        toolChoice: const AutoToolChoice(),
      );

      expect(config.tools, isNotNull);
      expect(config.tools!.length, equals(1));
      expect(config.tools!.first.function.name, equals('get_weather'));
      expect(config.toolChoice, isNotNull);
      expect(config.toolChoice!.toJson()['type'], equals('auto'));
    });

    test('should handle tool choice correctly', () {
      final testCases = [
        (const AutoToolChoice(), {'type': 'auto'}),
        (const AnyToolChoice(), {'type': 'required'}),
        (const NoneToolChoice(), {'type': 'none'}),
        (
          const SpecificToolChoice('get_weather'),
          {
            'type': 'function',
            'function': {'name': 'get_weather'}
          }
        ),
      ];

      for (final (toolChoice, expectedJson) in testCases) {
        expect(toolChoice.toJson(), equals(expectedJson),
            reason:
                'Tool choice ${toolChoice.runtimeType} should serialize correctly');
      }
    });
  });
}
