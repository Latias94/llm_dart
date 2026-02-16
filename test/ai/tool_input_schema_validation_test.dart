library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('local tool input schema validation', () {
    test('ToolSchemas.automatic validates input schema and errors on mismatch',
        () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'get_weather',
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
          handler: (input, options) => {'temp': 70},
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'get_weather', arguments: '{}'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: toolSet.tools,
        toolHandlers: toolSet.handlers,
        toolCatalog: ToolSetCatalog(toolSet),
        toolSchemas: ToolSchemas.automatic,
      );

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.toolCallId, equals('call_1'));
      expect(r.isError, isTrue);
      expect(r.metadata, isNotNull);
      expect(r.metadata!['kind'], equals('invalid_tool_call'));
      expect(r.metadata!['reason'], equals('schema_validation_failed'));
      expect(r.metadata!['toolName'], equals('get_weather'));
      expect(r.metadata!['errors'], isA<List>());
    });

    test('ToolSchemas.none skips input schema validation', () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'get_weather',
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
          handler: (input, options) => {'temp': 70},
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'get_weather', arguments: '{}'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: toolSet.tools,
        toolHandlers: toolSet.handlers,
        toolCatalog: ToolSetCatalog(toolSet),
        toolSchemas: ToolSchemas.none,
      );

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.toolCallId, equals('call_1'));
      expect(r.isError, isFalse);
      expect(r.result, equals({'temp': 70}));
    });
  });
}
