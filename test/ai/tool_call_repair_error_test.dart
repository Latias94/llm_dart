import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('tool call repair errors', () {
    test('repairToolCall throwing becomes an invalid_tool_call tool result',
        () async {
      final tool = Tool.function(
        name: 'get_weather',
        description: 'get weather',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {
            'city': ParameterProperty(propertyType: 'string', description: 'c'),
          },
          required: ['city'],
        ),
      );

      const call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(name: 'get_weather', arguments: '{'),
      );

      final results = await executeToolCalls(
        toolCalls: const [call],
        tools: [tool],
        toolHandlers: {
          'get_weather': (input, options) => {'temp': 70},
        },
        repairToolCall: (toolCall,
            {required reason, errorMessage, validationErrors}) {
          throw StateError('boom');
        },
        continueOnToolError: true,
      );

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.toolCallId, equals('call_1'));
      expect(r.isError, isTrue);
      expect(r.metadata, isNotNull);
      expect(r.metadata!['kind'], equals('invalid_tool_call'));
      expect(r.metadata!['repairAttempted'], isTrue);
      expect(r.result.toString(), contains('Tool call repair error'));
      expect(r.metadata!['repairError'].toString(),
          contains('Tool call repair error'));
    });
  });
}
