import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('Tool Parameter Validation Tests', () {
    group('Type Validation', () {
      test('should validate string parameters', () {
        final tool = Tool.function(
          name: 'string_test',
          description: 'Test string validation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'text': ParameterProperty(
                propertyType: 'string',
                description: 'Text parameter',
              ),
            },
            required: ['text'],
          ),
        );

        // Valid string
        final validCall = ToolCall(
          id: 'call_1',
          callType: 'function',
          function: FunctionCall(
            name: 'string_test',
            arguments: '{"text": "hello world"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validCall, tool),
            returnsNormally);

        // Invalid type (number instead of string)
        final invalidCall = ToolCall(
          id: 'call_2',
          callType: 'function',
          function: FunctionCall(
            name: 'string_test',
            arguments: '{"text": 123}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));
      });

      test('should validate number parameters', () {
        final tool = Tool.function(
          name: 'number_test',
          description: 'Test number validation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'value': ParameterProperty(
                propertyType: 'number',
                description: 'Number parameter',
              ),
            },
            required: ['value'],
          ),
        );

        // Valid integer
        final validIntCall = ToolCall(
          id: 'call_1',
          callType: 'function',
          function: FunctionCall(
            name: 'number_test',
            arguments: '{"value": 42}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validIntCall, tool),
            returnsNormally);

        // Valid float
        final validFloatCall = ToolCall(
          id: 'call_2',
          callType: 'function',
          function: FunctionCall(
            name: 'number_test',
            arguments: '{"value": 3.14}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validFloatCall, tool),
            returnsNormally);

        // Invalid type (string instead of number)
        final invalidCall = ToolCall(
          id: 'call_3',
          callType: 'function',
          function: FunctionCall(
            name: 'number_test',
            arguments: '{"value": "not a number"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));
      });

      test('should validate integer parameters', () {
        final tool = Tool.function(
          name: 'integer_test',
          description: 'Test integer validation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'count': ParameterProperty(
                propertyType: 'integer',
                description: 'Integer parameter',
              ),
            },
            required: ['count'],
          ),
        );

        // Valid integer
        final validCall = ToolCall(
          id: 'call_1',
          callType: 'function',
          function: FunctionCall(
            name: 'integer_test',
            arguments: '{"count": 10}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validCall, tool),
            returnsNormally);

        // Invalid type (float instead of integer)
        final invalidCall = ToolCall(
          id: 'call_2',
          callType: 'function',
          function: FunctionCall(
            name: 'integer_test',
            arguments: '{"count": 3.14}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));
      });

      test('should validate boolean parameters', () {
        final tool = Tool.function(
          name: 'boolean_test',
          description: 'Test boolean validation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'enabled': ParameterProperty(
                propertyType: 'boolean',
                description: 'Boolean parameter',
              ),
            },
            required: ['enabled'],
          ),
        );

        // Valid true
        final validTrueCall = ToolCall(
          id: 'call_1',
          callType: 'function',
          function: FunctionCall(
            name: 'boolean_test',
            arguments: '{"enabled": true}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validTrueCall, tool),
            returnsNormally);

        // Valid false
        final validFalseCall = ToolCall(
          id: 'call_2',
          callType: 'function',
          function: FunctionCall(
            name: 'boolean_test',
            arguments: '{"enabled": false}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validFalseCall, tool),
            returnsNormally);

        // Invalid type (string instead of boolean)
        final invalidCall = ToolCall(
          id: 'call_3',
          callType: 'function',
          function: FunctionCall(
            name: 'boolean_test',
            arguments: '{"enabled": "true"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));
      });

      test('should validate array parameters', () {
        final tool = Tool.function(
          name: 'array_test',
          description: 'Test array validation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'items': ParameterProperty(
                propertyType: 'array',
                description: 'Array parameter',
                items: ParameterProperty(
                  propertyType: 'string',
                  description: 'Array item',
                ),
              ),
            },
            required: ['items'],
          ),
        );

        // Valid array
        final validCall = ToolCall(
          id: 'call_1',
          callType: 'function',
          function: FunctionCall(
            name: 'array_test',
            arguments: '{"items": ["item1", "item2", "item3"]}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validCall, tool),
            returnsNormally);

        // Empty array (should be valid)
        final emptyArrayCall = ToolCall(
          id: 'call_2',
          callType: 'function',
          function: FunctionCall(
            name: 'array_test',
            arguments: '{"items": []}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(emptyArrayCall, tool),
            returnsNormally);

        // Invalid type (not an array)
        final invalidCall = ToolCall(
          id: 'call_3',
          callType: 'function',
          function: FunctionCall(
            name: 'array_test',
            arguments: '{"items": "not an array"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));

        // Invalid array item type
        final invalidItemCall = ToolCall(
          id: 'call_4',
          callType: 'function',
          function: FunctionCall(
            name: 'array_test',
            arguments: '{"items": ["valid", 123, "also valid"]}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidItemCall, tool),
            throwsA(isA<ToolValidationError>()));
      });
    });

    group('Enum Validation', () {
      test('should validate enum values', () {
        final tool = Tool.function(
          name: 'enum_test',
          description: 'Test enum validation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'status': ParameterProperty(
                propertyType: 'string',
                description: 'Status enum',
                enumList: ['active', 'inactive', 'pending'],
              ),
            },
            required: ['status'],
          ),
        );

        // Valid enum values
        for (final status in ['active', 'inactive', 'pending']) {
          final validCall = ToolCall(
            id: 'call_$status',
            callType: 'function',
            function: FunctionCall(
              name: 'enum_test',
              arguments: '{"status": "$status"}',
            ),
          );
          expect(() => ToolValidator.validateToolCall(validCall, tool),
              returnsNormally);
        }

        // Invalid enum value
        final invalidCall = ToolCall(
          id: 'call_invalid',
          callType: 'function',
          function: FunctionCall(
            name: 'enum_test',
            arguments: '{"status": "invalid_status"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));
      });

      test('should validate enum in nested structures', () {
        final tool = Tool.function(
          name: 'nested_enum_test',
          description: 'Test nested enum validation',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'config': ParameterProperty(
                propertyType: 'object',
                description: 'Config object',
                properties: {
                  'level': ParameterProperty(
                    propertyType: 'string',
                    description: 'Level enum',
                    enumList: ['debug', 'info', 'warn', 'error'],
                  ),
                },
                required: ['level'],
              ),
            },
            required: ['config'],
          ),
        );

        // Valid nested enum
        final validCall = ToolCall(
          id: 'call_valid',
          callType: 'function',
          function: FunctionCall(
            name: 'nested_enum_test',
            arguments: '{"config": {"level": "info"}}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validCall, tool),
            returnsNormally);

        // Invalid nested enum
        final invalidCall = ToolCall(
          id: 'call_invalid',
          callType: 'function',
          function: FunctionCall(
            name: 'nested_enum_test',
            arguments: '{"config": {"level": "invalid_level"}}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));
      });
    });

    group('Edge Cases', () {
      test('should handle missing optional parameters', () {
        final tool = Tool.function(
          name: 'optional_test',
          description: 'Test optional parameters',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'required_param': ParameterProperty(
                propertyType: 'string',
                description: 'Required parameter',
              ),
              'optional_param': ParameterProperty(
                propertyType: 'string',
                description: 'Optional parameter',
              ),
            },
            required: ['required_param'],
          ),
        );

        // Valid without optional parameter
        final validCall = ToolCall(
          id: 'call_1',
          callType: 'function',
          function: FunctionCall(
            name: 'optional_test',
            arguments: '{"required_param": "value"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validCall, tool),
            returnsNormally);

        // Valid with optional parameter provided
        final validCall2 = ToolCall(
          id: 'call_2',
          callType: 'function',
          function: FunctionCall(
            name: 'optional_test',
            arguments:
                '{"required_param": "value", "optional_param": "optional_value"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validCall2, tool),
            returnsNormally);

        // Invalid with null optional parameter (null values are not allowed)
        final invalidCall = ToolCall(
          id: 'call_3',
          callType: 'function',
          function: FunctionCall(
            name: 'optional_test',
            arguments: '{"required_param": "value", "optional_param": null}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(invalidCall, tool),
            throwsA(isA<ToolValidationError>()));
      });

      test('should handle empty objects and arrays', () {
        final tool = Tool.function(
          name: 'empty_test',
          description: 'Test empty structures',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'empty_object': ParameterProperty(
                propertyType: 'object',
                description: 'Empty object',
                properties: {},
                required: [],
              ),
              'empty_array': ParameterProperty(
                propertyType: 'array',
                description: 'Empty array',
                items: ParameterProperty(
                  propertyType: 'string',
                  description: 'String item',
                ),
              ),
            },
            required: ['empty_object', 'empty_array'],
          ),
        );

        final validCall = ToolCall(
          id: 'call_empty',
          callType: 'function',
          function: FunctionCall(
            name: 'empty_test',
            arguments: '{"empty_object": {}, "empty_array": []}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(validCall, tool),
            returnsNormally);
      });

      test('should reject extra parameters', () {
        final tool = Tool.function(
          name: 'extra_params_test',
          description: 'Test extra parameters',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'expected_param': ParameterProperty(
                propertyType: 'string',
                description: 'Expected parameter',
              ),
            },
            required: ['expected_param'],
          ),
        );

        // Call with extra parameters (should be rejected)
        final callWithExtra = ToolCall(
          id: 'call_extra',
          callType: 'function',
          function: FunctionCall(
            name: 'extra_params_test',
            arguments:
                '{"expected_param": "value", "extra_param": "extra_value"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(callWithExtra, tool),
            throwsA(isA<ToolValidationError>()));

        // Call with only expected parameters (should be allowed)
        final callWithoutExtra = ToolCall(
          id: 'call_no_extra',
          callType: 'function',
          function: FunctionCall(
            name: 'extra_params_test',
            arguments: '{"expected_param": "value"}',
          ),
        );
        expect(() => ToolValidator.validateToolCall(callWithoutExtra, tool),
            returnsNormally);
      });

      test('should handle malformed JSON gracefully', () {
        final tool = Tool.function(
          name: 'json_test',
          description: 'Test JSON handling',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {
              'param': ParameterProperty(
                propertyType: 'string',
                description: 'Parameter',
              ),
            },
            required: ['param'],
          ),
        );

        final malformedCall = ToolCall(
          id: 'call_malformed',
          callType: 'function',
          function: FunctionCall(
            name: 'json_test',
            arguments: '{"param": "value"', // Missing closing brace
          ),
        );

        expect(() => ToolValidator.validateToolCall(malformedCall, tool),
            throwsA(isA<ToolValidationError>()));
      });
    });
  });
}
