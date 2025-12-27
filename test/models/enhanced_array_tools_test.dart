import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'dart:convert';

void main() {
  group('Enhanced Array Tools', () {
    test('ParameterProperty supports object properties and required fields',
        () {
      // Create a ParameterProperty with nested object structure
      final userProperty = ParameterProperty(
        propertyType: 'object',
        description: 'User object',
        properties: {
          'name': ParameterProperty(
            propertyType: 'string',
            description: 'User name',
          ),
          'age': ParameterProperty(
            propertyType: 'integer',
            description: 'User age',
          ),
          'active': ParameterProperty(
            propertyType: 'boolean',
            description: 'User active status',
          ),
        },
        required: ['name', 'age'],
      );

      // Test serialization
      final json = userProperty.toJson();
      expect(json['type'], equals('object'));
      expect(json['properties'], isA<Map<String, dynamic>>());
      expect(json['properties']['name']['type'], equals('string'));
      expect(json['required'], equals(['name', 'age']));

      // Test deserialization
      final reconstructed = ParameterProperty.fromJson(json);
      expect(reconstructed.propertyType, equals('object'));
      expect(reconstructed.properties!.length, equals(3));
      expect(reconstructed.required!.length, equals(2));
      expect(reconstructed.properties!['name']!.propertyType, equals('string'));
    });

    test('Tool with nested array of objects works correctly', () {
      // Create a tool with array of objects
      final tool = Tool.function(
        name: 'process_users',
        description: 'Process user array',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'users': ParameterProperty(
              propertyType: 'array',
              description: 'Array of users',
              items: ParameterProperty(
                propertyType: 'object',
                description: 'User object',
                properties: {
                  'name': ParameterProperty(
                    propertyType: 'string',
                    description: 'User name',
                  ),
                  'email': ParameterProperty(
                    propertyType: 'string',
                    description: 'User email',
                  ),
                },
                required: ['name'],
              ),
            ),
          },
          required: ['users'],
        ),
      );

      // Test tool serialization
      final toolJson = tool.toJson();
      expect(toolJson['function']['parameters']['properties']['users']['type'],
          equals('array'));
      expect(
          toolJson['function']['parameters']['properties']['users']['items']
              ['type'],
          equals('object'));
      expect(
          toolJson['function']['parameters']['properties']['users']['items']
              ['properties']['name']['type'],
          equals('string'));
    });

    test('ToolValidator validates nested object arrays correctly', () {
      // Create tool definition
      final tool = Tool.function(
        name: 'test_function',
        description: 'Test function',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'items': ParameterProperty(
              propertyType: 'array',
              description: 'Array of items',
              items: ParameterProperty(
                propertyType: 'object',
                description: 'Item object',
                properties: {
                  'id': ParameterProperty(
                    propertyType: 'string',
                    description: 'Item ID',
                  ),
                  'count': ParameterProperty(
                    propertyType: 'integer',
                    description: 'Item count',
                  ),
                },
                required: ['id'],
              ),
            ),
          },
          required: ['items'],
        ),
      );

      // Valid tool call
      final validToolCall = ToolCall(
        id: 'call_123',
        callType: 'function',
        function: FunctionCall(
          name: 'test_function',
          arguments: jsonEncode({
            'items': [
              {'id': 'item1', 'count': 5},
              {'id': 'item2', 'count': 3}
            ]
          }),
        ),
      );

      // Should validate successfully
      expect(() => ToolValidator.validateToolCall(validToolCall, tool),
          returnsNormally);

      // Invalid tool call - missing required field
      final invalidToolCall = ToolCall(
        id: 'call_124',
        callType: 'function',
        function: FunctionCall(
          name: 'test_function',
          arguments: jsonEncode({
            'items': [
              {'id': 'item1', 'count': 5},
              {'count': 3} // Missing required 'id' field
            ]
          }),
        ),
      );

      // Should throw validation error
      expect(() => ToolValidator.validateToolCall(invalidToolCall, tool),
          throwsA(isA<ToolValidationError>()));
    });

    test('Deep nesting works correctly', () {
      // Create deeply nested structure: array -> object -> array -> object
      final deepTool = Tool.function(
        name: 'deep_function',
        description: 'Deep nested structure',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'orders': ParameterProperty(
              propertyType: 'array',
              description: 'Array of orders',
              items: ParameterProperty(
                propertyType: 'object',
                description: 'Order object',
                properties: {
                  'id': ParameterProperty(
                    propertyType: 'string',
                    description: 'Order ID',
                  ),
                  'items': ParameterProperty(
                    propertyType: 'array',
                    description: 'Order items',
                    items: ParameterProperty(
                      propertyType: 'object',
                      description: 'Item object',
                      properties: {
                        'product': ParameterProperty(
                          propertyType: 'string',
                          description: 'Product name',
                        ),
                        'quantity': ParameterProperty(
                          propertyType: 'integer',
                          description: 'Quantity',
                        ),
                      },
                      required: ['product'],
                    ),
                  ),
                },
                required: ['id', 'items'],
              ),
            ),
          },
          required: ['orders'],
        ),
      );

      // Test serialization/deserialization of deep structure
      final json = deepTool.toJson();
      final reconstructed = Tool.fromJson(json);

      expect(reconstructed.function.name, equals('deep_function'));

      // Verify deep structure integrity
      final ordersParam =
          reconstructed.function.parameters.properties['orders']!;
      expect(ordersParam.propertyType, equals('array'));

      final orderObject = ordersParam.items!;
      expect(orderObject.propertyType, equals('object'));
      expect(orderObject.properties!['items']!.propertyType, equals('array'));

      final itemObject = orderObject.properties!['items']!.items!;
      expect(itemObject.propertyType, equals('object'));
      expect(itemObject.properties!['product']!.propertyType, equals('string'));
    });

    test('Enum validation works in nested structures', () {
      final tool = Tool.function(
        name: 'enum_test',
        description: 'Test enum validation',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'items': ParameterProperty(
              propertyType: 'array',
              description: 'Array with enum',
              items: ParameterProperty(
                propertyType: 'object',
                description: 'Object with enum',
                properties: {
                  'status': ParameterProperty(
                    propertyType: 'string',
                    description: 'Status enum',
                    enumList: ['active', 'inactive', 'pending'],
                  ),
                },
                required: ['status'],
              ),
            ),
          },
          required: ['items'],
        ),
      );

      // Valid enum value
      final validCall = ToolCall(
        id: 'call_enum_valid',
        callType: 'function',
        function: FunctionCall(
          name: 'enum_test',
          arguments: jsonEncode({
            'items': [
              {'status': 'active'}
            ]
          }),
        ),
      );

      expect(() => ToolValidator.validateToolCall(validCall, tool),
          returnsNormally);

      // Invalid enum value
      final invalidCall = ToolCall(
        id: 'call_enum_invalid',
        callType: 'function',
        function: FunctionCall(
          name: 'enum_test',
          arguments: jsonEncode({
            'items': [
              {'status': 'invalid_status'}
            ]
          }),
        ),
      );

      expect(() => ToolValidator.validateToolCall(invalidCall, tool),
          throwsA(isA<ToolValidationError>()));
    });
  });
}
