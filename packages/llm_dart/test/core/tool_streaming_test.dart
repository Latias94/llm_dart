import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'dart:async';

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
    group('ToolCallDeltaEvent', () {
      test('should create tool call delta event', () {
        final toolCall = ToolCall(
          id: 'call_123',
          callType: 'function',
          function: FunctionCall(
            name: 'test_function',
            arguments: '{"param": "value"}',
          ),
        );

        final event = ToolCallDeltaEvent(toolCall);

        expect(event.toolCall, equals(toolCall));
        expect(event.toolCall.id, equals('call_123'));
        expect(event.toolCall.function.name, equals('test_function'));
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

        final event = ToolCallDeltaEvent(partialToolCall);

        expect(event.toolCall.id, equals('call_partial'));
        expect(event.toolCall.function.name, equals('partial_function'));
        expect(event.toolCall.function.arguments, equals('{"incomplete": "'));
      });
    });

    group('Tool Call Streaming Simulation', () {
      test('should handle streaming tool call events', () async {
        final events = <ChatStreamEvent>[];
        final controller = StreamController<ChatStreamEvent>();

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

        // Simulate streaming events
        controller.add(TextDeltaEvent('I need to call a tool: '));
        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_stream_1',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{"location": "New York"}',
            ),
          ),
        ));
        controller.add(TextDeltaEvent('Let me check the weather for you.'));
        controller.add(CompletionEvent(mockResponse));
        controller.close();

        // Collect all events
        await for (final event in controller.stream) {
          events.add(event);
        }

        expect(events, hasLength(4));
        expect(events[0], isA<TextDeltaEvent>());
        expect(events[1], isA<ToolCallDeltaEvent>());
        expect(events[2], isA<TextDeltaEvent>());
        expect(events[3], isA<CompletionEvent>());

        final toolCallEvent = events[1] as ToolCallDeltaEvent;
        expect(toolCallEvent.toolCall.function.name, equals('get_weather'));
      });

      test('should handle multiple tool calls in stream', () async {
        final toolCallEvents = <ToolCallDeltaEvent>[];
        final controller = StreamController<ChatStreamEvent>();

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
        controller.add(TextDeltaEvent('I need to call multiple tools: '));
        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{"location": "New York"}',
            ),
          ),
        ));
        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_2',
            callType: 'function',
            function: FunctionCall(
              name: 'calculate',
              arguments: '{"expression": "2+2"}',
            ),
          ),
        ));
        controller.add(CompletionEvent(mockResponse));
        controller.close();

        // Collect tool call events
        await for (final event in controller.stream) {
          if (event is ToolCallDeltaEvent) {
            toolCallEvents.add(event);
          }
        }

        expect(toolCallEvents, hasLength(2));
        expect(toolCallEvents[0].toolCall.function.name, equals('get_weather'));
        expect(toolCallEvents[1].toolCall.function.name, equals('calculate'));
      });

      test('should handle streaming with incremental tool call building',
          () async {
        final controller = StreamController<ChatStreamEvent>();
        final toolCallParts = <String>[];

        // Simulate incremental tool call argument building
        controller.add(TextDeltaEvent('Calling function: '));
        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_incremental',
            callType: 'function',
            function: FunctionCall(
              name: 'search',
              arguments: '{"query": "', // Partial arguments
            ),
          ),
        ));
        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_incremental',
            callType: 'function',
            function: FunctionCall(
              name: 'search',
              arguments: '{"query": "weather', // More arguments
            ),
          ),
        ));
        controller.add(ToolCallDeltaEvent(
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
        await for (final event in controller.stream) {
          if (event is ToolCallDeltaEvent) {
            toolCallParts.add(event.toolCall.function.arguments);
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
        final controller = StreamController<ChatStreamEvent>();
        final events = <ChatStreamEvent>[];

        controller.add(TextDeltaEvent('Starting tool call...'));
        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_malformed',
            callType: 'function',
            function: FunctionCall(
              name: 'malformed_tool',
              arguments: 'invalid json', // Invalid JSON
            ),
          ),
        ));
        controller.add(TextDeltaEvent('Tool call completed.'));
        controller.close();

        await for (final event in controller.stream) {
          events.add(event);
        }

        expect(events, hasLength(3));
        final toolCallEvent = events[1] as ToolCallDeltaEvent;
        expect(
            toolCallEvent.toolCall.function.arguments, equals('invalid json'));
        // The streaming should continue despite malformed JSON
      });

      test('should handle empty tool call arguments in stream', () async {
        final controller = StreamController<ChatStreamEvent>();
        final toolCallEvents = <ToolCallDeltaEvent>[];

        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_empty',
            callType: 'function',
            function: FunctionCall(
              name: 'no_args_tool',
              arguments: '', // Empty arguments
            ),
          ),
        ));
        controller.add(ToolCallDeltaEvent(
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

        await for (final event in controller.stream) {
          if (event is ToolCallDeltaEvent) {
            toolCallEvents.add(event);
          }
        }

        expect(toolCallEvents, hasLength(2));
        expect(toolCallEvents[0].toolCall.function.arguments, equals(''));
        expect(toolCallEvents[1].toolCall.function.arguments, equals('{}'));
      });
    });

    group('Tool Call Event Ordering', () {
      test('should maintain correct event order in complex stream', () async {
        final controller = StreamController<ChatStreamEvent>();
        final eventTypes = <String>[];

        final mockResponse = MockChatResponse(id: 'final', text: 'Complete');

        // Complex streaming scenario
        controller.add(TextDeltaEvent('Starting analysis: '));
        eventTypes.add('text');

        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(name: 'analyze', arguments: '{}'),
          ),
        ));
        eventTypes.add('tool_call');

        controller.add(TextDeltaEvent('Analysis complete. Now calculating: '));
        eventTypes.add('text');

        controller.add(ToolCallDeltaEvent(
          ToolCall(
            id: 'call_2',
            callType: 'function',
            function: FunctionCall(name: 'calculate', arguments: '{}'),
          ),
        ));
        eventTypes.add('tool_call');

        controller.add(TextDeltaEvent('All done!'));
        eventTypes.add('text');

        controller.add(CompletionEvent(mockResponse));
        eventTypes.add('completion');

        controller.close();

        final actualEventTypes = <String>[];
        await for (final event in controller.stream) {
          if (event is TextDeltaEvent) {
            actualEventTypes.add('text');
          } else if (event is ToolCallDeltaEvent) {
            actualEventTypes.add('tool_call');
          } else if (event is CompletionEvent) {
            actualEventTypes.add('completion');
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
              'completion'
            ]));
      });
    });
  });
}
