import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/src/compatibility/providers/openai/openai_structured_output_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIStructuredOutputCodec', () {
    const codec = OpenAIStructuredOutputCodec();

    test('maps structured output format to OpenAI response_format JSON', () {
      const format = StructuredOutputFormat(
        name: 'answer',
        description: 'Structured answer payload.',
        strict: true,
        schema: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
        },
      );

      expect(codec.toJson(format), {
        'type': 'json_schema',
        'json_schema': {
          'name': 'answer',
          'description': 'Structured answer payload.',
          'schema': {
            'type': 'object',
            'properties': {
              'value': {'type': 'string'},
            },
            'additionalProperties': false,
          },
          'strict': true,
        },
      });
    });

    test('keeps schema-less payload minimal', () {
      const format = StructuredOutputFormat(
        name: 'answer',
      );

      expect(codec.toJson(format), {
        'type': 'json_schema',
        'json_schema': {'name': 'answer'},
      });
    });
  });
}
