import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Google Tool Calling Tests', () {
    late List<Tool> testTools;

    setUp(() {
      testTools = [
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
        Tool.function(
          name: 'calculate',
          description: 'Perform calculations',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'expression': ParameterProperty(
                propertyType: 'string',
                description: 'Mathematical expression',
              ),
            },
            required: ['expression'],
          ),
        ),
      ];
    });

    group('Tool Choice Configuration', () {
      test('should support AutoToolChoice in configuration', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const AutoToolChoice(),
        );

        expect(config.toolChoice, isA<AutoToolChoice>());
        expect(config.tools, equals(testTools));
      });

      test('should support AnyToolChoice in configuration', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const AnyToolChoice(),
        );

        expect(config.toolChoice, isA<AnyToolChoice>());
      });

      test('should support SpecificToolChoice in configuration', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const SpecificToolChoice('get_weather'),
        );

        expect(config.toolChoice, isA<SpecificToolChoice>());
        final specificChoice = config.toolChoice as SpecificToolChoice;
        expect(specificChoice.toolName, equals('get_weather'));
      });

      test('should support NoneToolChoice in configuration', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const NoneToolChoice(),
        );

        expect(config.toolChoice, isA<NoneToolChoice>());
      });

      test('should handle null toolChoice gracefully', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
        );

        expect(config.toolChoice, isNull);
        expect(config.tools, equals(testTools));
      });
    });

    group('ToolChoice JSON Serialization', () {
      test(
          'should serialize ToolChoice types correctly for Google compatibility',
          () {
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
          final json = toolChoice.toJson();
          expect(json, equals(expectedJson),
              reason: '${toolChoice.runtimeType} should serialize correctly');
        }
      });
    });

    group('Configuration Transformation', () {
      test(
          'should preserve toolChoice when creating GoogleConfig from LLMConfig',
          () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const SpecificToolChoice('calculate'),
          temperature: 0.7,
        );

        final googleConfig = GoogleConfig.fromLLMConfig(llmConfig);

        expect(googleConfig.toolChoice, isA<SpecificToolChoice>());
        expect(googleConfig.temperature, equals(0.7));
        expect(googleConfig.tools, equals(testTools));

        final specificChoice = googleConfig.toolChoice as SpecificToolChoice;
        expect(specificChoice.toolName, equals('calculate'));
      });

      test('should handle LLMConfig without toolChoice', () {
        final llmConfig = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
          model: 'gemini-1.5-flash',
          tools: testTools,
        );

        final googleConfig = GoogleConfig.fromLLMConfig(llmConfig);

        expect(googleConfig.toolChoice, isNull);
        expect(googleConfig.tools, equals(testTools));
      });
    });

    group('Config CopyWith Method', () {
      test('should copy config with new toolChoice', () {
        final originalConfig = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
        );

        final copiedConfig = originalConfig.copyWith(
          toolChoice: const AnyToolChoice(),
        );

        expect(copiedConfig.toolChoice, isA<AnyToolChoice>());
        expect(copiedConfig.apiKey, equals(originalConfig.apiKey));
        expect(copiedConfig.model, equals(originalConfig.model));
        expect(copiedConfig.tools, equals(originalConfig.tools));
      });

      test('should preserve existing toolChoice when not specified in copyWith',
          () {
        final originalConfig = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const SpecificToolChoice('original_tool'),
        );

        final copiedConfig = originalConfig.copyWith(
          temperature: 0.8,
        );

        expect(copiedConfig.toolChoice, isA<SpecificToolChoice>());
        final specificChoice = copiedConfig.toolChoice as SpecificToolChoice;
        expect(specificChoice.toolName, equals('original_tool'));
        expect(copiedConfig.temperature, equals(0.8));
      });
    });

    group('Provider Integration', () {
      test('should support tool calling capability', () {
        final config = const GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
        );
        final provider = GoogleProvider(config);

        expect(provider.supports(LLMCapability.toolCalling), isTrue);
        expect(
            provider.supportedCapabilities.contains(LLMCapability.toolCalling),
            isTrue);
      });

      test('should maintain toolChoice configuration in provider', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const SpecificToolChoice('get_weather'),
        );
        final provider = GoogleProvider(config);

        expect(provider.config.toolChoice, isA<SpecificToolChoice>());
        final specificChoice = provider.config.toolChoice as SpecificToolChoice;
        expect(specificChoice.toolName, equals('get_weather'));
      });

      test('should support all tool calling models', () {
        final models = [
          'gemini-1.5-flash',
          'gemini-1.5-pro',
          'gemini-2.0-flash-thinking',
          'gemini-exp-1206',
        ];

        for (final model in models) {
          final config = GoogleConfig(
            apiKey: 'test-key',
            model: model,
            toolChoice: const SpecificToolChoice('test_tool'),
          );
          expect(config.supportsToolCalling, isTrue,
              reason: 'Model $model should support tool calling');
        }
      });
    });

    group('Tool Choice Behavior Scenarios', () {
      test('should handle multiple tools with SpecificToolChoice', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const SpecificToolChoice('calculate'),
        );

        expect(config.tools!.length, equals(2));
        expect(config.toolChoice, isA<SpecificToolChoice>());

        final specificChoice = config.toolChoice as SpecificToolChoice;
        expect(specificChoice.toolName, equals('calculate'));

        // Verify the specified tool exists in the tools list
        final hasCalculateTool =
            config.tools!.any((tool) => tool.function.name == 'calculate');
        expect(hasCalculateTool, isTrue);
      });

      test('should preserve configuration integrity with all parameters', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          temperature: 0.7,
          maxTokens: 1000,
          tools: testTools,
          toolChoice: const AnyToolChoice(),
          topP: 0.9,
          topK: 40,
        );

        expect(config.temperature, equals(0.7));
        expect(config.maxTokens, equals(1000));
        expect(config.toolChoice, isA<AnyToolChoice>());
        expect(config.tools, equals(testTools));
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(40));
      });
    });

    group('Validation and Edge Cases', () {
      test('should handle SpecificToolChoice with non-existent tool name', () {
        // Configuration should still accept the tool choice even if tool doesn't exist
        // (validation happens at runtime in the actual API call)
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const SpecificToolChoice('non_existent_tool'),
        );

        expect(config.toolChoice, isA<SpecificToolChoice>());
        final specificChoice = config.toolChoice as SpecificToolChoice;
        expect(specificChoice.toolName, equals('non_existent_tool'));
      });

      test('should handle empty tools list with SpecificToolChoice', () {
        final config = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: [],
          toolChoice: const SpecificToolChoice('any_tool'),
        );

        expect(config.tools!.isEmpty, isTrue);
        expect(config.toolChoice, isA<SpecificToolChoice>());
        final specificChoice = config.toolChoice as SpecificToolChoice;
        expect(specificChoice.toolName, equals('any_tool'));
      });
    });

    group('Regression Tests', () {
      test('should ensure toolChoice was missing before the fix', () {
        // This test documents that toolChoice was previously not supported
        // and verifies it's now properly supported

        // Create config the old way (without toolChoice)
        const oldStyleConfig = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
        );

        // Create config the new way (with toolChoice)
        final newStyleConfig = GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
          tools: testTools,
          toolChoice: const SpecificToolChoice('get_weather'),
        );

        expect(oldStyleConfig.toolChoice, isNull);
        expect(newStyleConfig.toolChoice, isNotNull);
        expect(newStyleConfig.toolChoice, isA<SpecificToolChoice>());
      });
    });
  });
}
