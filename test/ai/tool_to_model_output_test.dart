library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('local tool toModelOutput', () {
    test('applies toModelOutput when handler returns non-envelope output',
        () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'emit',
          description: 'emit content output',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          toModelOutput: toModelContentValue((output) {
            return const [ToolResultContentText('hello')];
          }),
          handler: (input, options) => {'ignored': true},
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'emit', arguments: '{}'),
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
      final part = ToolResultPart.fromToolCall(toolResultCalls.single);
      expect(part.output, isA<ToolResultContentOutput>());
      final output = part.output as ToolResultContentOutput;
      expect(output.value, hasLength(1));
      expect(output.value.single, isA<ToolResultContentText>());
      expect(
          (output.value.single as ToolResultContentText).text, equals('hello'));
    });

    test('outputSchema validates ToolResultJsonOutput.value from toModelOutput',
        () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'sum',
          description: 'sum numbers',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          outputSchema: Schema.object(
            'sum output',
            properties: {'result': Schema.integer('result')},
            required: ['result'],
          ),
          toModelOutput: toModelJsonValue((output) {
            final raw = output?.toString() ?? '';
            final parsed = int.tryParse(raw) ?? 0;
            return {'result': parsed};
          }),
          handler: (input, options) => '3',
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'sum', arguments: '{}'),
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

    test('toModelOutput can produce ToolResultErrorTextOutput', () async {
      final toolSet = ToolSet([
        functionTool(
          name: 'fail',
          description: 'fail',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          toModelOutput: toModelErrorTextValue((output) => 'nope'),
          handler: (input, options) => {'ignored': true},
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
    });

    test('does not call toModelOutput when handler returns ToolResultOutput',
        () async {
      var called = false;

      final toolSet = ToolSet([
        functionTool(
          name: 'direct',
          description: 'direct',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          toModelOutput: toModelOutput((toolCallId, input, output, options) {
            called = true;
            throw StateError('should not be called');
          }),
          handler: (input, options) => const ToolResultTextOutput('ok'),
        ),
      ]);

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'direct', arguments: '{}'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: toolSet.tools,
        toolHandlers: toolSet.handlers,
        toolCatalog: ToolSetCatalog(toolSet),
      );

      expect(called, isFalse);
      expect(results.single.isError, isFalse);
      expect((results.single.result as Map)['type'], equals('text'));
    });
  });
}
