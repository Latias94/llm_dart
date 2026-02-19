import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'dart:convert';

void main() {
  group('Enhanced JSON Schema tools', () {
    test('Schema builders support nested objects and required fields', () {
      final schema = Schema.object(
        'User object',
        properties: {
          'name': Schema.string('User name'),
          'age': Schema.integer('User age'),
          'active': Schema.boolean('User active status'),
        },
        required: const ['name', 'age'],
      );

      expect(schema['type'], equals('object'));
      expect(schema['properties'], isA<Map<String, dynamic>>());
      expect((schema['properties'] as Map)['name']['type'], equals('string'));
      expect(schema['required'], equals(['name', 'age']));
    });

    test('Tool with nested array of objects serializes as inputSchema', () {
      final tool = Tool.function(
        name: 'process_users',
        description: 'Process user array',
        inputSchema: Schema.params(
          properties: {
            'users': Schema.array(
              'Array of users',
              items: Schema.object(
                'User object',
                properties: {
                  'name': Schema.string('User name'),
                  'email': Schema.string('User email'),
                },
                required: const ['name'],
              ),
            ),
          },
          required: const ['users'],
        ),
      );

      final toolJson = tool.toJson();
      final inputSchema = toolJson['inputSchema'] as Map;
      final users = (inputSchema['properties'] as Map)['users'] as Map;
      expect(users['type'], equals('array'));
      expect((users['items'] as Map)['type'], equals('object'));
      expect(
        (((users['items'] as Map)['properties'] as Map)['name'] as Map)['type'],
        equals('string'),
      );
    });

    test('ToolValidator validates nested object arrays correctly', () {
      final tool = Tool.function(
        name: 'test_function',
        description: 'Test function',
        inputSchema: Schema.params(
          properties: {
            'items': Schema.array(
              'Array of items',
              items: Schema.object(
                'Item object',
                properties: {
                  'id': Schema.string('Item ID'),
                  'count': Schema.integer('Item count'),
                },
                required: const ['id'],
              ),
            ),
          },
          required: const ['items'],
        ),
      );

      final validToolCall = ToolCall(
        id: 'call_123',
        callType: 'function',
        function: FunctionCall(
          name: 'test_function',
          arguments: jsonEncode({
            'items': [
              {'id': 'item1', 'count': 5},
              {'id': 'item2', 'count': 3},
            ],
          }),
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(validToolCall, tool),
        returnsNormally,
      );

      final invalidToolCall = ToolCall(
        id: 'call_124',
        callType: 'function',
        function: FunctionCall(
          name: 'test_function',
          arguments: jsonEncode({
            'items': [
              {'id': 'item1', 'count': 5},
              {'count': 3},
            ],
          }),
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(invalidToolCall, tool),
        throwsA(isA<ToolValidationError>()),
      );
    });

    test('Deep nesting round-trips through Tool.toJson/fromJson', () {
      final deepTool = Tool.function(
        name: 'deep_function',
        description: 'Deep nested structure',
        inputSchema: Schema.params(
          properties: {
            'orders': Schema.array(
              'Array of orders',
              items: Schema.object(
                'Order object',
                properties: {
                  'id': Schema.string('Order ID'),
                  'items': Schema.array(
                    'Order items',
                    items: Schema.object(
                      'Item object',
                      properties: {
                        'product': Schema.string('Product name'),
                        'quantity': Schema.integer('Quantity'),
                      },
                      required: const ['product'],
                    ),
                  ),
                },
                required: const ['id', 'items'],
              ),
            ),
          },
          required: const ['orders'],
        ),
      );

      final json = deepTool.toJson();
      final reconstructed = Tool.fromJson(json);

      expect(reconstructed.function.name, equals('deep_function'));

      final schema = reconstructed.function.inputSchema;
      final orders = (schema['properties'] as Map)['orders'] as Map;
      expect(orders['type'], equals('array'));

      final orderObject = orders['items'] as Map;
      expect(orderObject['type'], equals('object'));

      final orderItems = (orderObject['properties'] as Map)['items'] as Map;
      expect(orderItems['type'], equals('array'));

      final itemObject = orderItems['items'] as Map;
      expect(itemObject['type'], equals('object'));
      expect(
        (((itemObject['properties'] as Map)['product'] as Map)['type']),
        equals('string'),
      );
    });

    test('Enum validation works in nested structures', () {
      final tool = Tool.function(
        name: 'enum_test',
        description: 'Test enum validation',
        inputSchema: Schema.params(
          properties: {
            'items': Schema.array(
              'Array with enum',
              items: Schema.object(
                'Object with enum',
                properties: {
                  'status': Schema.string(
                    'Status enum',
                    enumValues: const ['active', 'inactive', 'pending'],
                  ),
                },
                required: const ['status'],
              ),
            ),
          },
          required: const ['items'],
        ),
      );

      final validCall = ToolCall(
        id: 'call_enum_valid',
        callType: 'function',
        function: FunctionCall(
          name: 'enum_test',
          arguments: jsonEncode({
            'items': [
              {'status': 'active'}
            ],
          }),
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(validCall, tool),
        returnsNormally,
      );

      final invalidCall = ToolCall(
        id: 'call_enum_invalid',
        callType: 'function',
        function: FunctionCall(
          name: 'enum_test',
          arguments: jsonEncode({
            'items': [
              {'status': 'invalid_status'}
            ],
          }),
        ),
      );

      expect(
        () => ToolValidator.validateToolCall(invalidCall, tool),
        throwsA(isA<ToolValidationError>()),
      );
    });
  });
}
