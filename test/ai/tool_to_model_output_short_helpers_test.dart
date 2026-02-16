library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('toModel* short helpers', () {
    test('toModelTextValue produces type=text envelope', () async {
      final toolSet = ToolSet([
        functionTool(
          name: 't',
          description: 't',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          toModelOutput: toModelTextValue((output) => output.toString()),
          handler: (input, options) => 123,
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 't', arguments: '{}'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: toolSet.tools,
        toolHandlers: toolSet.handlers,
        toolCatalog: ToolSetCatalog(toolSet),
      );

      expect(results.single.isError, isFalse);
      expect((results.single.result as Map)['type'], equals('text'));
    });

    test('toModelExecutionDeniedReason produces type=execution-denied envelope',
        () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'deny',
          description: 'deny',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          toModelOutput: toModelExecutionDeniedReason((output) => 'no'),
          handler: (input, options) => {'ignored': true},
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'deny', arguments: '{}'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: toolSet.tools,
        toolHandlers: toolSet.handlers,
        toolCatalog: ToolSetCatalog(toolSet),
      );

      expect(results.single.isError, isFalse);
      expect(
          (results.single.result as Map)['type'], equals('execution-denied'));
    });
  });
}
