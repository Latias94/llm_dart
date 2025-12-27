import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Tool Models Tests', () {
    group('ParameterProperty', () {
      test('should create with required fields', () {
        final property = ParameterProperty(
          propertyType: 'string',
          description: 'A test parameter',
        );

        expect(property.propertyType, equals('string'));
        expect(property.description, equals('A test parameter'));
        expect(property.enumList, isNull);
        expect(property.items, isNull);
      });

      test('should create with all fields', () {
        final property = ParameterProperty(
          propertyType: 'string',
          description: 'A complex parameter',
          enumList: ['option1', 'option2'],
          items: ParameterProperty(
            propertyType: 'string',
            description: 'Array item',
          ),
        );

        expect(property.propertyType, equals('string'));
        expect(property.description, equals('A complex parameter'));
        expect(property.enumList, equals(['option1', 'option2']));
        expect(property.items, isNotNull);
      });

      test('should serialize to JSON correctly', () {
        final property = ParameterProperty(
          propertyType: 'string',
          description: 'A test parameter',
          enumList: ['option1', 'option2'],
        );

        final json = property.toJson();
        expect(json['type'], equals('string'));
        expect(json['description'], equals('A test parameter'));
        expect(json['enum'], equals(['option1', 'option2']));
      });
    });

    group('ParametersSchema', () {
      test('should create with required fields', () {
        final schema = ParametersSchema(
          schemaType: 'object',
          properties: {
            'param1': ParameterProperty(
              propertyType: 'string',
              description: 'First parameter',
            ),
          },
          required: [],
        );

        expect(schema.schemaType, equals('object'));
        expect(schema.properties, hasLength(1));
        expect(schema.required, isEmpty);
      });

      test('should create with all fields', () {
        final schema = ParametersSchema(
          schemaType: 'object',
          properties: {
            'param1': ParameterProperty(
              propertyType: 'string',
              description: 'First parameter',
            ),
            'param2': ParameterProperty(
              propertyType: 'number',
              description: 'Second parameter',
            ),
          },
          required: ['param1'],
        );

        expect(schema.schemaType, equals('object'));
        expect(schema.properties, hasLength(2));
        expect(schema.required, equals(['param1']));
      });

      test('should serialize to JSON correctly', () {
        final schema = ParametersSchema(
          schemaType: 'object',
          properties: {
            'param1': ParameterProperty(
              propertyType: 'string',
              description: 'First parameter',
            ),
          },
          required: ['param1'],
        );

        final json = schema.toJson();
        expect(json['type'], equals('object'));
        expect(json['properties'], isA<Map>());
        expect(json['required'], equals(['param1']));
      });
    });

    group('FunctionTool', () {
      test('should create with required fields', () {
        final function = FunctionTool(
          name: 'test_function',
          description: 'A test function',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        );

        expect(function.name, equals('test_function'));
        expect(function.description, equals('A test function'));
        expect(function.parameters, isNotNull);
      });

      test('should serialize to JSON correctly', () {
        final function = FunctionTool(
          name: 'test_function',
          description: 'A test function',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        );

        final json = function.toJson();
        expect(json['name'], equals('test_function'));
        expect(json['description'], equals('A test function'));
        expect(json['parameters'], isA<Map>());
      });
    });

    group('Tool', () {
      test('should create function tool', () {
        final tool = Tool.function(
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
        );

        expect(tool.function.name, equals('get_weather'));
        expect(tool.function.description, equals('Get weather information'));
      });

      test('should serialize to JSON correctly', () {
        final tool = Tool.function(
          name: 'get_weather',
          description: 'Get weather information',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        );

        final json = tool.toJson();
        expect(json['type'], equals('function'));
        expect(json['function'], isA<Map>());
        expect(json['function']['name'], equals('get_weather'));
      });
    });

    group('ProviderTool', () {
      test('should infer provider id from stable id', () {
        const tool = ProviderTool(id: 'openai.web_search_preview');
        expect(tool.inferredProviderId, equals('openai'));
      });

      test('should serialize to JSON correctly', () {
        const tool = ProviderTool(
          id: 'openai.file_search',
          options: {
            'vectorStoreIds': ['vs_123']
          },
        );

        final json = tool.toJson();
        expect(json['id'], equals('openai.file_search'));
        expect(
            json['options'],
            equals({
              'vectorStoreIds': ['vs_123']
            }));
      });

      test('should deserialize from JSON correctly', () {
        final tool = ProviderTool.fromJson({
          'id': 'anthropic.web_search_20250305',
          'options': {'maxUses': 3},
        });

        expect(tool.id, equals('anthropic.web_search_20250305'));
        expect(tool.options, equals({'maxUses': 3}));
      });
    });

    group('ToolChoice Classes', () {
      test('AutoToolChoice should serialize correctly', () {
        const choice = AutoToolChoice();
        final json = choice.toJson();
        expect(json['type'], equals('auto'));
      });

      test('AutoToolChoice with parallel disable should format for Anthropic',
          () {
        const choice = AutoToolChoice(disableParallelToolUse: true);
        final anthropicJson = choice.toAnthropicJson();
        expect(anthropicJson, contains('disable_parallel_tool_use'));
      });

      test('AnyToolChoice should serialize correctly', () {
        const choice = AnyToolChoice();
        final json = choice.toJson();
        expect(json['type'], equals('required'));
      });

      test('NoneToolChoice should serialize correctly', () {
        const choice = NoneToolChoice();
        final json = choice.toJson();
        expect(json['type'], equals('none'));
      });

      test('SpecificToolChoice should serialize correctly', () {
        const choice = SpecificToolChoice('get_weather');
        final json = choice.toJson();
        expect(json['type'], equals('function'));
        expect(json['function']['name'], equals('get_weather'));
      });

      test('ToolChoice should convert to Anthropic format correctly', () {
        const autoChoice = AutoToolChoice();
        expect(autoChoice.toAnthropicJson(), equals('auto'));

        const anyChoice = AnyToolChoice();
        expect(anyChoice.toAnthropicJson(), equals('any'));

        const noneChoice = NoneToolChoice();
        expect(noneChoice.toAnthropicJson(), equals('none'));

        const specificChoice = SpecificToolChoice('get_weather');
        expect(specificChoice.toAnthropicJson(), contains('get_weather'));
      });
    });

    group('FunctionCall', () {
      test('should create with required fields', () {
        final call = FunctionCall(
          name: 'get_weather',
          arguments: '{"location": "New York"}',
        );

        expect(call.name, equals('get_weather'));
        expect(call.arguments, equals('{"location": "New York"}'));
      });

      test('should serialize to JSON correctly', () {
        final call = FunctionCall(
          name: 'get_weather',
          arguments: '{"location": "New York"}',
        );

        final json = call.toJson();
        expect(json['name'], equals('get_weather'));
        expect(json['arguments'], equals('{"location": "New York"}'));
      });
    });

    group('ToolCall', () {
      test('should create with required fields', () {
        final toolCall = ToolCall(
          id: 'call_123',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location": "New York"}',
          ),
        );

        expect(toolCall.id, equals('call_123'));
        expect(toolCall.function.name, equals('get_weather'));
        expect(toolCall.callType, equals('function'));
      });

      test('should serialize to JSON correctly', () {
        final toolCall = ToolCall(
          id: 'call_123',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location": "New York"}',
          ),
        );

        final json = toolCall.toJson();
        expect(json['id'], equals('call_123'));
        expect(json['type'], equals('function'));
        expect(json['function'], isA<Map>());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'call_456',
          'type': 'function',
          'function': {
            'name': 'calculate',
            'arguments': '{"expression": "2+2"}',
          },
        };

        final toolCall = ToolCall.fromJson(json);
        expect(toolCall.id, equals('call_456'));
        expect(toolCall.callType, equals('function'));
        expect(toolCall.function.name, equals('calculate'));
        expect(toolCall.function.arguments, equals('{"expression": "2+2"}'));
      });

      test('should handle toString correctly', () {
        final toolCall = ToolCall(
          id: 'call_789',
          callType: 'function',
          function: FunctionCall(
            name: 'test_func',
            arguments: '{"param": "value"}',
          ),
        );

        final stringRepresentation = toolCall.toString();
        expect(stringRepresentation, contains('call_789'));
        expect(stringRepresentation, contains('test_func'));
      });
    });

    group('ToolResult', () {
      test('should create successful result', () {
        final result = ToolResult.success(
          toolCallId: 'call_123',
          content: 'Operation completed successfully',
          metadata: {'duration': 150},
        );

        expect(result.toolCallId, equals('call_123'));
        expect(result.content, equals('Operation completed successfully'));
        expect(result.isError, isFalse);
        expect(result.metadata?['duration'], equals(150));
      });

      test('should create error result', () {
        final result = ToolResult.error(
          toolCallId: 'call_456',
          errorMessage: 'Tool execution failed',
          metadata: {'error_code': 500},
        );

        expect(result.toolCallId, equals('call_456'));
        expect(result.content, equals('Tool execution failed'));
        expect(result.isError, isTrue);
        expect(result.metadata?['error_code'], equals(500));
      });

      test('should serialize to JSON correctly', () {
        final result = ToolResult(
          toolCallId: 'call_789',
          content: 'Test result',
          isError: false,
          metadata: {'key': 'value'},
        );

        final json = result.toJson();
        expect(json['tool_call_id'], equals('call_789'));
        expect(json['content'], equals('Test result'));
        expect(json['is_error'], isFalse);
        expect(json['metadata']['key'], equals('value'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'tool_call_id': 'call_999',
          'content': 'Deserialized result',
          'is_error': true,
          'metadata': {'source': 'test'},
        };

        final result = ToolResult.fromJson(json);
        expect(result.toolCallId, equals('call_999'));
        expect(result.content, equals('Deserialized result'));
        expect(result.isError, isTrue);
        expect(result.metadata?['source'], equals('test'));
      });

      test('should handle missing optional fields in JSON', () {
        final json = {
          'tool_call_id': 'call_minimal',
          'content': 'Minimal result',
        };

        final result = ToolResult.fromJson(json);
        expect(result.toolCallId, equals('call_minimal'));
        expect(result.content, equals('Minimal result'));
        expect(result.isError, isFalse); // Default value
        expect(result.metadata, isNull);
      });
    });
  });
}
