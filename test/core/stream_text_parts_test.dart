import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

/// Mock ChatResponse for testing stream adaptation.
class _MockChatResponse extends ChatResponse {
  final String? _text;
  final List<ToolCall>? _toolCalls;
  final String? _thinking;
  final UsageInfo? _usage;

  _MockChatResponse({
    String? text,
    List<ToolCall>? toolCalls,
    String? thinking,
    UsageInfo? usage,
  })  : _text = text,
        _toolCalls = toolCalls,
        _thinking = thinking,
        _usage = usage;

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
  group('adaptStreamText', () {
    test(
        'emits tool input lifecycle and final tool call for incremental tool chunks',
        () async {
      // Simulate a streaming sequence with text + incremental tool call chunks.
      final source = Stream<ChatStreamEvent>.fromIterable([
        const TextDeltaEvent('Hello '),
        const ToolCallDeltaEvent(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{"location": "',
            ),
          ),
        ),
        const ToolCallDeltaEvent(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: 'Paris"}',
            ),
          ),
        ),
        CompletionEvent(
          _MockChatResponse(
            text: 'Done',
          ),
        ),
      ]);

      final parts = await adaptStreamText(source).toList();

      // We expect:
      // - StreamTextStart
      // - StreamTextDelta
      // - StreamToolInputStart
      // - StreamToolInputDelta (first chunk)
      // - StreamToolInputDelta (second chunk)
      // - StreamToolInputEnd
      // - StreamToolCall (final tool call)
      // - StreamTextEnd
      // - StreamFinish
      expect(
        parts.map((e) => e.runtimeType).toList(),
        equals([
          StreamTextStart,
          StreamTextDelta,
          StreamToolInputStart,
          StreamToolInputDelta,
          StreamToolInputDelta,
          StreamToolInputEnd,
          StreamToolCall,
          StreamTextEnd,
          StreamFinish,
        ]),
      );

      final toolStart = parts.whereType<StreamToolInputStart>().single;
      final toolDeltas = parts.whereType<StreamToolInputDelta>().toList();
      final toolEnd = parts.whereType<StreamToolInputEnd>().single;
      final toolCall = parts.whereType<StreamToolCall>().single.toolCall;

      expect(toolStart.toolCallId, 'call_1');
      expect(toolStart.toolName, 'get_weather');

      expect(toolDeltas.map((d) => d.delta).toList(), [
        '{"location": "',
        'Paris"}',
      ]);

      expect(toolEnd.toolCallId, 'call_1');
      expect(toolCall.id, 'call_1');
      expect(toolCall.function.name, 'get_weather');
      expect(toolCall.function.arguments, '{"location": "Paris"}');
    });
  });
}
