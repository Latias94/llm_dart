library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('local tool ToolResultOutput envelope', () {
    test('handler can return ToolResultContentOutput', () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'emit_content',
          description: 'emit content output',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          handler: (input, options) => ToolResultContentOutput(
            const [
              ToolResultContentText('hello'),
            ],
          ),
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'emit_content', arguments: '{}'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: toolSet.tools,
        toolHandlers: toolSet.handlers,
        toolCatalog: ToolSetCatalog(toolSet),
      );

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.isError, isFalse);
      expect(r.result, isA<Map>());
      expect((r.result as Map)['type'], equals('content'));

      final toolResultCalls = encodeToolResultsAsToolCalls(
        toolCalls: const [call],
        toolResults: results,
      );
      expect(toolResultCalls, hasLength(1));

      final part = ToolResultPart.fromToolCall(toolResultCalls.single);
      expect(part.toolCallId, equals('call_1'));
      expect(part.toolName, equals('emit_content'));
      expect(part.output, isA<ToolResultContentOutput>());
      final output = part.output as ToolResultContentOutput;
      expect(output.value, hasLength(1));
      expect(output.value.first, isA<ToolResultContentText>());
      expect(
          (output.value.first as ToolResultContentText).text, equals('hello'));
    });

    test('handler can return ToolResultErrorTextOutput and sets isError',
        () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'fail',
          description: 'emit error output',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          handler: (input, options) => const ToolResultErrorTextOutput('nope'),
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'fail', arguments: '{}'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: toolSet.tools,
        toolHandlers: toolSet.handlers,
        toolCatalog: ToolSetCatalog(toolSet),
      );

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.isError, isTrue);
      expect(r.result, isA<Map>());
      expect((r.result as Map)['type'], equals('error-text'));

      final toolResultCalls = encodeToolResultsAsToolCalls(
        toolCalls: const [call],
        toolResults: results,
      );
      expect(toolResultCalls, hasLength(1));

      final part = ToolResultPart.fromToolCall(toolResultCalls.single);
      expect(part.output, isA<ToolResultErrorTextOutput>());
      expect((part.output as ToolResultErrorTextOutput).value, equals('nope'));
    });
  });
}
