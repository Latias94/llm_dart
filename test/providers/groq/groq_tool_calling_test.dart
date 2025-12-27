import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Groq Tool Calling Tests', () {
    test('should not maintain a tool calling capability matrix', () {
      final models = [
        'llama-4-scout-17b-16e-instruct',
        'llama-3-8b-base',
        'mixtral-8x7b-base',
        'gemma2-9b-it',
        'unknown-model',
      ];

      for (final model in models) {
        final config = GroqConfig(
          apiKey: 'test-key',
          model: model,
        );
        expect(config.supportsToolCalling, isTrue);
        expect(config.supportsParallelToolCalling, isTrue);
      }
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
