import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Tool Parameter Validation', () {
    test('validates string parameter', () {
      final tool = Tool.function(
        name: 'string_test',
        description: 'Test string validation',
        inputSchema: Schema.params(
          properties: {'text': Schema.string('Text parameter')},
          required: const ['text'],
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'string_test',
              arguments: '{"text":"hello"}',
            ),
          ),
          tool,
        ),
        returnsNormally,
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'call_2',
            callType: 'function',
            function: FunctionCall(
              name: 'string_test',
              arguments: '{"text":123}',
            ),
          ),
          tool,
        ),
        throwsA(isA<ToolValidationError>()),
      );
    });

    test('validates number and integer', () {
      final numberTool = Tool.function(
        name: 'number_test',
        description: 'Test number validation',
        inputSchema: Schema.params(
          properties: {'value': Schema.number('Number parameter')},
          required: const ['value'],
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'n1',
            callType: 'function',
            function: FunctionCall(
              name: 'number_test',
              arguments: '{"value":3.14}',
            ),
          ),
          numberTool,
        ),
        returnsNormally,
      );

      final integerTool = Tool.function(
        name: 'integer_test',
        description: 'Test integer validation',
        inputSchema: Schema.params(
          properties: {'count': Schema.integer('Integer parameter')},
          required: const ['count'],
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'i1',
            callType: 'function',
            function: FunctionCall(
              name: 'integer_test',
              arguments: '{"count":10}',
            ),
          ),
          integerTool,
        ),
        returnsNormally,
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'i2',
            callType: 'function',
            function: FunctionCall(
              name: 'integer_test',
              arguments: '{"count":3.14}',
            ),
          ),
          integerTool,
        ),
        throwsA(isA<ToolValidationError>()),
      );
    });

    test('validates nested objects and arrays', () {
      final tool = Tool.function(
        name: 'complex_test',
        description: 'Test complex structures',
        inputSchema: Schema.params(
          properties: {
            'items': Schema.array(
              'Items',
              items: Schema.object(
                'Item',
                properties: {
                  'id': Schema.string('id'),
                  'active': Schema.boolean('active'),
                },
                required: const ['id'],
              ),
            ),
          },
          required: const ['items'],
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'c1',
            callType: 'function',
            function: FunctionCall(
              name: 'complex_test',
              arguments:
                  '{"items":[{"id":"a","active":true},{"id":"b","active":false}]}',
            ),
          ),
          tool,
        ),
        returnsNormally,
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'c2',
            callType: 'function',
            function: FunctionCall(
              name: 'complex_test',
              arguments: '{"items":[{"active":true}]}',
            ),
          ),
          tool,
        ),
        throwsA(isA<ToolValidationError>()),
      );
    });

    test('rejects extra parameters when additionalProperties=false', () {
      final tool = Tool.function(
        name: 'no_extra',
        description: 'No extra params',
        inputSchema: {
          'type': 'object',
          'properties': {
            'expected': {'type': 'string', 'description': 'expected'},
          },
          'required': const ['expected'],
          'additionalProperties': false,
        },
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'e1',
            callType: 'function',
            function: FunctionCall(
              name: 'no_extra',
              arguments: '{"expected":"ok","extra":"no"}',
            ),
          ),
          tool,
        ),
        throwsA(isA<ToolValidationError>()),
      );
    });

    test('handles malformed JSON gracefully', () {
      final tool = Tool.function(
        name: 'json_test',
        description: 'Test JSON handling',
        inputSchema: Schema.params(
          properties: {'param': Schema.string('param')},
          required: const ['param'],
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(
          const ToolCall(
            id: 'm1',
            callType: 'function',
            function: FunctionCall(
              name: 'json_test',
              arguments: '{"param":"value"',
            ),
          ),
          tool,
        ),
        throwsA(isA<ToolValidationError>()),
      );
    });
  });
}

