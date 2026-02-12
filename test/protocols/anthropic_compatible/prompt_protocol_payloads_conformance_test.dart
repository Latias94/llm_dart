import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic-compatible Prompt protocolPayloads conformance', () {
    test('preserves provider-native contentBlocks when present', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: PromptRole.user,
            parts: [TextPart('Hi')],
          ),
          PromptMessage(
            role: PromptRole.assistant,
            parts: const [
              TextPart('should be ignored when contentBlocks are present'),
            ],
            protocolPayloads: const {
              'anthropic': {
                'contentBlocks': [
                  {
                    'type': 'thinking',
                    'thinking': 'I should call the tool.',
                    'signature': 'sig_123',
                  },
                  {
                    'type': 'text',
                    'text': 'Let me check.',
                  },
                  {
                    'type': 'tool_use',
                    'id': 'toolu_1',
                    'name': 'getWeather',
                    'input': {'city': 'London'},
                  },
                ],
              },
            },
          ),
        ],
      );

      final built = builder.buildRequestFromPrompt(
        prompt,
        [
          Tool.function(
            name: 'getWeather',
            description: 'get weather',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {
                'city': ParameterProperty(
                  propertyType: 'string',
                  description: 'city',
                ),
              },
              required: ['city'],
            ),
          ),
        ],
        false,
      );

      final messages = built.body['messages'] as List<dynamic>;
      expect(messages, hasLength(2));

      final assistant = messages[1] as Map<String, dynamic>;
      expect(assistant['role'], equals('assistant'));

      expect(
        assistant['content'],
        equals([
          {
            'type': 'thinking',
            'thinking': 'I should call the tool.',
            'signature': 'sig_123',
          },
          {'type': 'text', 'text': 'Let me check.'},
          {
            'type': 'tool_use',
            'id': 'toolu_1',
            'name': 'getWeather',
            'input': {'city': 'London'},
          },
        ]),
      );
    });
  });
}
