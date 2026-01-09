import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic tool definition extras (AI SDK parity)', () {
    test('includes strict, input_examples, defer_loading, allowed_callers', () {
      final config = AnthropicConfig(
        apiKey: 'k',
        model: 'm',
        providerId: 'anthropic',
      );

      final builder = AnthropicRequestBuilder(config);

      final tool = Tool.function(
        name: 't',
        description: 'd',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {},
          required: [],
        ),
        strict: true,
        inputExamples: const [
          {'a': 1},
        ],
        providerOptions: const {
          'anthropic': {
            'deferLoading': true,
            'allowedCallers': ['code_execution_20250825'],
          },
        },
      );

      final body = builder.buildRequestBody(
        [ChatMessage.user('hi')],
        [tool],
        false,
      );

      final tools = (body['tools'] as List).cast<Map>();
      expect(tools, hasLength(1));
      final def = tools.single.cast<String, dynamic>();
      expect(def['name'], equals('t'));
      expect(def['strict'], isTrue);
      expect(def['input_examples'], equals(const [{'a': 1}]));
      expect(def['defer_loading'], isTrue);
      expect(def['allowed_callers'], equals(const ['code_execution_20250825']));
    });
  });
}

