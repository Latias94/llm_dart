import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/testing.dart' as anthropic_pkg;
import 'package:test/test.dart';

void main() {
  group('AnthropicRequestBuilder call options', () {
    Tool testTool() {
      return Tool.function(
        name: 'get_weather',
        description: 'Get current weather',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: const ['location'],
        ),
      );
    }

    test('options.tools is honored when tools arg is null', () {
      final config = anthropic_pkg.AnthropicConfig(
        apiKey: 'test',
        model: 'claude-sonnet-4-20250514',
      );
      final builder = anthropic_pkg.AnthropicRequestBuilder(config);

      final tool = testTool();
      final body = builder.buildRequestBodyFromPrompt(
        [ModelMessage.userText('Hello')],
        null,
        false,
        options: LanguageModelCallOptions(tools: [tool]),
      );

      expect(body['tools'], isA<List>());
      final toolsList = (body['tools'] as List).cast<Map<String, dynamic>>();
      expect(toolsList, hasLength(1));
      expect(toolsList.first['name'], equals('get_weather'));
    });

    test('options.toolChoice overrides config.toolChoice', () {
      final config = anthropic_pkg.AnthropicConfig(
        apiKey: 'test',
        model: 'claude-sonnet-4-20250514',
        toolChoice: const NoneToolChoice(),
      );
      final builder = anthropic_pkg.AnthropicRequestBuilder(config);

      final body = builder.buildRequestBodyFromPrompt(
        [ModelMessage.userText('Hello')],
        null,
        false,
        options: LanguageModelCallOptions(
          tools: [testTool()],
          toolChoice: const AutoToolChoice(),
        ),
      );

      expect(body['tool_choice'], equals('auto'));
    });

    test('stopSequences/user/serviceTier prefer per-call options', () {
      final config = anthropic_pkg.AnthropicConfig(
        apiKey: 'test',
        model: 'claude-sonnet-4-20250514',
        stopSequences: const ['CONFIG_STOP'],
        user: 'config-user',
        serviceTier: ServiceTier.priority,
      );
      final builder = anthropic_pkg.AnthropicRequestBuilder(config);

      final body = builder.buildRequestBodyFromPrompt(
        [ModelMessage.userText('Hello')],
        null,
        false,
        options: LanguageModelCallOptions(
          stopSequences: ['CALL_STOP'],
          user: 'call-user',
          serviceTier: ServiceTier.standard,
          metadata: {
            'trace_id': 'abc123',
          },
        ),
      );

      expect(body['stop_sequences'], equals(['CALL_STOP']));
      expect(body['service_tier'], equals(ServiceTier.standard.value));

      expect(body['metadata'], isA<Map<String, dynamic>>());
      final metadata = body['metadata'] as Map<String, dynamic>;
      expect(metadata['user_id'], equals('call-user'));
      expect(metadata['trace_id'], equals('abc123'));
    });

    test('empty callTools disables config tools', () {
      final config = anthropic_pkg.AnthropicConfig(
        apiKey: 'test',
        model: 'claude-sonnet-4-20250514',
        tools: [testTool()],
      );
      final builder = anthropic_pkg.AnthropicRequestBuilder(config);

      final body = builder.buildRequestBodyFromPrompt(
        [ModelMessage.userText('Hello')],
        null,
        false,
        options: const LanguageModelCallOptions(callTools: []),
      );

      expect(body.containsKey('tools'), isFalse);
      expect(body.containsKey('tool_choice'), isFalse);
    });
  });
}
