library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('dynamicTool', () {
    test('converts inputSchema object to ParametersSchema', () async {
      final toolSet = ToolSet([
        dynamicTool(
          name: 'get_weather',
          description: 'get weather',
          inputSchema: Schema.object(
            'params',
            properties: {
              'city': Schema.string('city'),
            },
            required: ['city'],
          ),
          execute: (input, options) => {'temp': 70},
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
      expect(results.single.isError, isTrue);
      expect(results.single.metadata, isNotNull);
      expect(results.single.metadata!['reason'],
          equals('schema_validation_failed'));
    });

    test('supports toModelOutput mapping', () async {
      final toolSet = ToolSet([
        dynamicTool(
          name: 'sum',
          description: 'sum numbers',
          inputSchema: Schema.object(
            'params',
            properties: {
              'a': Schema.integer('a'),
              'b': Schema.integer('b'),
            },
            required: ['a', 'b'],
          ),
          outputSchema: Schema.object(
            'output',
            properties: {'result': Schema.integer('result')},
            required: ['result'],
          ),
          toModelOutput: toModelJsonValue((output) => output),
          execute: (input, options) => {
            'result': (input['a'] as int) + (input['b'] as int),
          },
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
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
      expect(r.isError, isFalse);
      expect(r.result, isA<Map>());
      expect((r.result as Map)['type'], equals('json'));
    });
  });
}
