import 'dart:async';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

/// Mock ChatResponse for testing
class MockChatResponse extends ChatResponse {
  final String _id;
  final String? _text;
  final List<ToolCall>? _toolCalls;
  final String? _thinking;
  final UsageInfo? _usage;

  MockChatResponse({
    required String id,
    String? text,
    List<ToolCall>? toolCalls,
    String? thinking,
    UsageInfo? usage,
  })  : _id = id,
        _text = text,
        _toolCalls = toolCalls,
        _thinking = thinking,
        _usage = usage;

  String get id => _id;

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => _toolCalls;

  @override
  String? get thinking => _thinking;

  @override
  UsageInfo? get usage => _usage;
}

void main() {
  group('Tool Streaming Tests', () {
    group('LLMToolCallDeltaPart', () {
      test('should create tool call delta part', () {
        final toolCall = ToolCall(
          id: 'call_123',
          callType: 'function',
          function: FunctionCall(
            name: 'test_function',
            arguments: '{"param": "value"}',
          ),
        );

        final part = LLMToolCallDeltaPart(toolCall);

        expect(part.toolCall, equals(toolCall));
        expect(part.toolCall.id, equals('call_123'));
        expect(part.toolCall.function.name, equals('test_function'));
      });

      test('should handle partial tool call data', () {
        final partialToolCall = ToolCall(
          id: 'call_partial',
          callType: 'function',
          function: FunctionCall(
            name: 'partial_function',
            arguments: '{"incomplete": "', // Incomplete JSON
          ),
        );

        final part = LLMToolCallDeltaPart(partialToolCall);

        expect(part.toolCall.id, equals('call_partial'));
        expect(part.toolCall.function.name, equals('partial_function'));
        expect(part.toolCall.function.arguments, equals('{"incomplete": "'));
      });
    });

    group('Tool Call Streaming Simulation', () {
      test('should handle streaming tool call parts', () async {
        final parts = <LLMStreamPart>[];
        final controller = StreamController<LLMStreamPart>();

        // Create a mock response for testing
        final mockResponse = MockChatResponse(
          id: 'response_123',
          text: 'I need to call a tool: Let me check the weather for you.',
          toolCalls: [
            ToolCall(
              id: 'call_stream_1',
              callType: 'function',
              function: FunctionCall(
                name: 'get_weather',
                arguments: '{"location": "New York"}',
              ),
            ),
          ],
        );

        // Simulate streaming parts
        controller.add(const LLMTextDeltaPart('I need to call a tool: '));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_stream_1',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{"location": "New York"}',
            ),
          ),
        ));
        controller.add(
          const LLMTextDeltaPart('Let me check the weather for you.'),
        );
        controller.add(LLMFinishPart(mockResponse));
        controller.close();

        // Collect all parts
        await for (final part in controller.stream) {
          parts.add(part);
        }

        expect(parts, hasLength(4));
        expect(parts[0], isA<LLMTextDeltaPart>());
        expect(parts[1], isA<LLMToolCallDeltaPart>());
        expect(parts[2], isA<LLMTextDeltaPart>());
        expect(parts[3], isA<LLMFinishPart>());

        final toolCallPart = parts[1] as LLMToolCallDeltaPart;
        expect(toolCallPart.toolCall.function.name, equals('get_weather'));
      });

      test('should handle multiple tool calls in stream', () async {
        final toolCallParts = <LLMToolCallDeltaPart>[];
        final controller = StreamController<LLMStreamPart>();

        final mockResponse = MockChatResponse(
          id: 'response_multi',
          text: 'I need to call multiple tools: ',
          toolCalls: [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(
                name: 'get_weather',
                arguments: '{"location": "New York"}',
              ),
            ),
            ToolCall(
              id: 'call_2',
              callType: 'function',
              function: FunctionCall(
                name: 'calculate',
                arguments: '{"expression": "2+2"}',
              ),
            ),
          ],
        );

        // Simulate multiple tool calls
        controller.add(const LLMTextDeltaPart('I need to call multiple tools: '));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{"location": "New York"}',
            ),
          ),
        ));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_2',
            callType: 'function',
            function: FunctionCall(
              name: 'calculate',
              arguments: '{"expression": "2+2"}',
            ),
          ),
        ));
        controller.add(LLMFinishPart(mockResponse));
        controller.close();

        // Collect tool call parts
        await for (final part in controller.stream) {
          if (part is LLMToolCallDeltaPart) {
            toolCallParts.add(part);
          }
        }

        expect(toolCallParts, hasLength(2));
        expect(toolCallParts[0].toolCall.function.name, equals('get_weather'));
        expect(toolCallParts[1].toolCall.function.name, equals('calculate'));
      });

      test('should handle streaming with incremental tool call building',
          () async {
        final controller = StreamController<LLMStreamPart>();
        final toolCallParts = <String>[];

        // Simulate incremental tool call argument building
        controller.add(const LLMTextDeltaPart('Calling function: '));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_incremental',
            callType: 'function',
            function: FunctionCall(
              name: 'search',
              arguments: '{"query": "', // Partial arguments
            ),
          ),
        ));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_incremental',
            callType: 'function',
            function: FunctionCall(
              name: 'search',
              arguments: '{"query": "weather', // More arguments
            ),
          ),
        ));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_incremental',
            callType: 'function',
            function: FunctionCall(
              name: 'search',
              arguments: '{"query": "weather in Tokyo"}', // Complete arguments
            ),
          ),
        ));
        controller.close();

        // Collect tool call arguments progression
        await for (final part in controller.stream) {
          if (part is LLMToolCallDeltaPart) {
            toolCallParts.add(part.toolCall.function.arguments);
          }
        }

        expect(toolCallParts, hasLength(3));
        expect(toolCallParts[0], equals('{"query": "'));
        expect(toolCallParts[1], equals('{"query": "weather'));
        expect(toolCallParts[2], equals('{"query": "weather in Tokyo"}'));
      });
    });

    group('Error Handling in Streaming', () {
      test('should handle malformed tool call in stream', () async {
        final controller = StreamController<LLMStreamPart>();
        final parts = <LLMStreamPart>[];

        controller.add(const LLMTextDeltaPart('Starting tool call...'));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_malformed',
            callType: 'function',
            function: FunctionCall(
              name: 'malformed_tool',
              arguments: 'invalid json', // Invalid JSON
            ),
          ),
        ));
        controller.add(const LLMTextDeltaPart('Tool call completed.'));
        controller.close();

        await for (final part in controller.stream) {
          parts.add(part);
        }

        expect(parts, hasLength(3));
        final toolCallPart = parts[1] as LLMToolCallDeltaPart;
        expect(
            toolCallPart.toolCall.function.arguments, equals('invalid json'));
        // The streaming should continue despite malformed JSON
      });

      test('should handle empty tool call arguments in stream', () async {
        final controller = StreamController<LLMStreamPart>();
        final toolCallParts = <LLMToolCallDeltaPart>[];

        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_empty',
            callType: 'function',
            function: FunctionCall(
              name: 'no_args_tool',
              arguments: '', // Empty arguments
            ),
          ),
        ));
        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_empty_json',
            callType: 'function',
            function: FunctionCall(
              name: 'empty_json_tool',
              arguments: '{}', // Empty JSON
            ),
          ),
        ));
        controller.close();

        await for (final part in controller.stream) {
          if (part is LLMToolCallDeltaPart) {
            toolCallParts.add(part);
          }
        }

        expect(toolCallParts, hasLength(2));
        expect(toolCallParts[0].toolCall.function.arguments, equals(''));
        expect(toolCallParts[1].toolCall.function.arguments, equals('{}'));
      });
    });

    group('Tool Call Event Ordering', () {
      test('should maintain correct event order in complex stream', () async {
        final controller = StreamController<LLMStreamPart>();
        final eventTypes = <String>[];

        final mockResponse = MockChatResponse(id: 'final', text: 'Complete');

        // Complex streaming scenario
        controller.add(const LLMTextDeltaPart('Starting analysis: '));
        eventTypes.add('text');

        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(name: 'analyze', arguments: '{}'),
          ),
        ));
        eventTypes.add('tool_call');

        controller.add(const LLMTextDeltaPart('Analysis complete. Now calculating: '));
        eventTypes.add('text');

        controller.add(LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_2',
            callType: 'function',
            function: FunctionCall(name: 'calculate', arguments: '{}'),
          ),
        ));
        eventTypes.add('tool_call');

        controller.add(const LLMTextDeltaPart('All done!'));
        eventTypes.add('text');

        controller.add(LLMFinishPart(mockResponse));
        eventTypes.add('finish');

        controller.close();

        final actualEventTypes = <String>[];
        await for (final part in controller.stream) {
          if (part is LLMTextDeltaPart) {
            actualEventTypes.add('text');
          } else if (part is LLMToolCallDeltaPart) {
            actualEventTypes.add('tool_call');
          } else if (part is LLMFinishPart) {
            actualEventTypes.add('finish');
          }
        }

        expect(actualEventTypes, equals(eventTypes));
        expect(
            actualEventTypes,
            equals([
              'text',
              'tool_call',
              'text',
              'tool_call',
              'text',
              'finish'
            ]));
      });
    });
  });
}
