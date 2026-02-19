library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('local tool outputSchema validation', () {
    test(
        'ToolSchemas.automatic validates outputSchema and returns ToolResult.error on mismatch',
        () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'sum',
          description: 'sum numbers',
          inputSchema: Schema.params(
            properties: {
              'a': Schema.integer('a'),
              'b': Schema.integer('b'),
            },
            required: ['a', 'b'],
          ),
          outputSchema: Schema.object(
            'sum output',
            properties: {'result': Schema.integer('result')},
            required: ['result'],
          ),
          handler: (input, options) => {'result': 'not-an-int'},
        ),
      ]);

      const rawArguments = '{"a":1,"b":2}';
      const call = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'sum',
        input: rawArguments,
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
      expect(r.metadata!['kind'], equals('invalid_tool_output'));
      expect(r.metadata!['reason'], equals('output_schema_validation_failed'));
      expect(r.metadata!['toolName'], equals('sum'));
      expect(r.metadata!['errors'], isA<List>());
    });

    test('ToolSchemas.none skips outputSchema validation', () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'sum',
          description: 'sum numbers',
          inputSchema: Schema.params(
            properties: {
              'a': Schema.integer('a'),
              'b': Schema.integer('b'),
            },
            required: ['a', 'b'],
          ),
          outputSchema: Schema.object(
            'sum output',
            properties: {'result': Schema.integer('result')},
            required: ['result'],
          ),
          handler: (input, options) => {'result': 'not-an-int'},
        ),
      ]);

      const rawArguments = '{"a":1,"b":2}';
      const call = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'sum',
        input: rawArguments,
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
      expect(r.result, equals({'result': 'not-an-int'}));
    });

    test('ToolSchemas.automatic accepts output matching outputSchema',
        () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'sum',
          description: 'sum numbers',
          inputSchema: Schema.params(
            properties: {
              'a': Schema.integer('a'),
              'b': Schema.integer('b'),
            },
            required: ['a', 'b'],
          ),
          outputSchema: Schema.object(
            'sum output',
            properties: {'result': Schema.integer('result')},
            required: ['result'],
          ),
          handler: (input, options) => {'result': 3},
        ),
      ]);

      const rawArguments = '{"a":1,"b":2}';
      const call = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'sum',
        input: rawArguments,
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
      expect(r.isError, isFalse);
      expect(r.result, equals({'result': 3}));
    });
  });
}
