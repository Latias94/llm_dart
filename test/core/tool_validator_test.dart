import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'dart:convert';

void main() {
  group('ToolValidator Tests', () {
    Tool? weatherTool;
    Tool? calculatorTool;
    Tool? complexTool;

    setUp(() {
      // Simple weather tool
      weatherTool = Tool.function(
        name: 'get_weather',
        description: 'Get weather information',
        inputSchema: Schema.params(
          properties: {
            'location': Schema.string('City name'),
            'units': Schema.string(
              'Temperature units',
              enumValues: const ['celsius', 'fahrenheit'],
            ),
          },
          required: const ['location'],
        ),
      );

      // Calculator tool
      calculatorTool = Tool.function(
        name: 'calculate',
        description: 'Perform calculations',
        inputSchema: Schema.params(
          properties: {
            'expression': Schema.string('Math expression'),
            'precision': Schema.integer('Decimal precision'),
          },
          required: const ['expression'],
        ),
      );

      // Complex nested tool
      complexTool = Tool.function(
        name: 'process_data',
        description: 'Process complex data',
        inputSchema: Schema.params(
          properties: {
            'data': Schema.array(
              'Data array',
              items: Schema.object(
                'Data item',
                properties: {
                  'id': Schema.string('Item ID'),
                  'value': Schema.number('Item value'),
                  'active': Schema.boolean('Is active'),
                },
                required: const ['id', 'value'],
              ),
            ),
          },
          required: const ['data'],
        ),
      );
    });

    group('validateToolCall', () {
      test('should validate correct tool call', () {
        final toolCall = ToolCall(
          id: 'call_123',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location": "New York", "units": "celsius"}',
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, weatherTool!),
            returnsNormally);
      });

      test('should validate tool call with only required parameters', () {
        final toolCall = ToolCall(
          id: 'call_124',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location": "London"}',
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, weatherTool!),
            returnsNormally);
      });

      test('should throw error for wrong tool name', () {
        final toolCall = ToolCall(
          id: 'call_125',
          callType: 'function',
          function: FunctionCall(
            name: 'wrong_name',
            arguments: '{"location": "Paris"}',
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, weatherTool!),
            throwsA(isA<ToolValidationError>()));
      });

      test('should throw error for invalid JSON arguments', () {
        final toolCall = ToolCall(
          id: 'call_126',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: 'invalid json',
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, weatherTool!),
            throwsA(isA<ToolValidationError>()));
      });

      test('should throw error for missing required parameter', () {
        final toolCall = ToolCall(
          id: 'call_127',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"units": "celsius"}',
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, weatherTool!),
            throwsA(isA<ToolValidationError>()));
      });

      test('should throw error for invalid enum value', () {
        final toolCall = ToolCall(
          id: 'call_128',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location": "Tokyo", "units": "kelvin"}',
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, weatherTool!),
            throwsA(isA<ToolValidationError>()));
      });

      test('should validate complex nested structures', () {
        final toolCall = ToolCall(
          id: 'call_129',
          callType: 'function',
          function: FunctionCall(
            name: 'process_data',
            arguments: jsonEncode({
              'data': [
                {'id': 'item1', 'value': 42.5, 'active': true},
                {'id': 'item2', 'value': 13.7, 'active': false},
              ]
            }),
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, complexTool!),
            returnsNormally);
      });

      test('should throw error for invalid nested structure', () {
        final toolCall = ToolCall(
          id: 'call_130',
          callType: 'function',
          function: FunctionCall(
            name: 'process_data',
            arguments: jsonEncode({
              'data': [
                {
                  'id': 'item1',
                  'value': 42.5
                }, // Missing required 'active' is OK
                {'value': 13.7, 'active': false}, // Missing required 'id'
              ]
            }),
          ),
        );

        expect(() => ToolValidator.validateToolCall(toolCall, complexTool!),
            throwsA(isA<ToolValidationError>()));
      });
    });

    group('validateToolChoice', () {
      late List<Tool> availableTools;

      setUp(() {
        availableTools = [weatherTool!, calculatorTool!];
      });

      test('should validate AutoToolChoice', () {
        const choice = AutoToolChoice();
        expect(() => ToolValidator.validateToolChoice(choice, availableTools),
            returnsNormally);
      });

      test('should validate AnyToolChoice', () {
        const choice = AnyToolChoice();
        expect(() => ToolValidator.validateToolChoice(choice, availableTools),
            returnsNormally);
      });

      test('should validate NoneToolChoice', () {
        const choice = NoneToolChoice();
        expect(() => ToolValidator.validateToolChoice(choice, availableTools),
            returnsNormally);
      });

      test('should validate SpecificToolChoice with existing tool', () {
        const choice = SpecificToolChoice('get_weather');
        expect(() => ToolValidator.validateToolChoice(choice, availableTools),
            returnsNormally);
      });

      test('should throw error for SpecificToolChoice with non-existing tool',
          () {
        const choice = SpecificToolChoice('non_existing_tool');
        expect(() => ToolValidator.validateToolChoice(choice, availableTools),
            throwsA(isA<ToolValidationError>()));
      });
    });

    group('findTool', () {
      late List<Tool> tools;

      setUp(() {
        tools = [weatherTool!, calculatorTool!, complexTool!];
      });

      test('should find existing tool', () {
        final found = ToolValidator.findTool('get_weather', tools);
        expect(found, isNotNull);
        expect(found!.function.name, equals('get_weather'));
      });

      test('should return null for non-existing tool', () {
        final found = ToolValidator.findTool('non_existing', tools);
        expect(found, isNull);
      });
    });

    group('validateToolCalls', () {
      late List<Tool> availableTools;

      setUp(() {
        availableTools = [weatherTool!, calculatorTool!];
      });

      test('should validate multiple correct tool calls', () {
        final toolCalls = [
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{"location": "New York"}',
            ),
          ),
          ToolCall(
            id: 'call_2',
            callType: 'function',
            function: FunctionCall(
              name: 'calculate',
              arguments: '{"expression": "2+2"}',
            ),
          ),
        ];

        final errors =
            ToolValidator.validateToolCalls(toolCalls, availableTools);
        expect(errors, isEmpty);
      });

      test('should return errors for invalid tool calls', () {
        final toolCalls = [
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'non_existing_tool',
              arguments: '{"param": "value"}',
            ),
          ),
          ToolCall(
            id: 'call_2',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{}', // Missing required parameter
            ),
          ),
        ];

        final errors =
            ToolValidator.validateToolCalls(toolCalls, availableTools);
        expect(errors, hasLength(2));
        expect(errors['call_1'], isNotEmpty);
        expect(errors['call_2'], isNotEmpty);
      });
    });
  });
}
