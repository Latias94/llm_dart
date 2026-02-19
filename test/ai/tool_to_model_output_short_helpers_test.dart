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
          inputSchema: Schema.params(properties: const {}),
          toModelOutput: toModelTextValue((output) => output.toString()),
          handler: (input, options) => 123,
        ),
      ]);

      const call = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 't',
        input: '{}',
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
          inputSchema: Schema.params(properties: const {}),
          toModelOutput: toModelExecutionDeniedReason((output) => 'no'),
          handler: (input, options) => {'ignored': true},
        ),
      ]);

      const call = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'deny',
        input: '{}',
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
