import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

/// Mock ChatResponse for testing stream adaptation.
class _MockChatResponse extends ChatResponse {
  final String? _text;
  final List<ToolCall>? _toolCalls;
  final String? _thinking;
  final UsageInfo? _usage;
  final List<CallWarning> _warnings;
  final Map<String, dynamic>? _metadata;

  _MockChatResponse({
    String? text,
    List<ToolCall>? toolCalls,
    String? thinking,
    UsageInfo? usage,
    List<CallWarning> warnings = const [],
    Map<String, dynamic>? metadata,
  })  : _text = text,
        _toolCalls = toolCalls,
        _thinking = thinking,
        _usage = usage,
        _warnings = warnings,
        _metadata = metadata;

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => _toolCalls;

  @override
  String? get thinking => _thinking;

  @override
  UsageInfo? get usage => _usage;

  @override
  List<CallWarning> get warnings => _warnings;

  @override
  Map<String, dynamic>? get metadata => _metadata;
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

    test('propagates response fields into StreamFinish result', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: FunctionCall(
          name: 'do_something',
          arguments: '{"value": 1}',
        ),
      );

      const usage = UsageInfo(
        promptTokens: 3,
        completionTokens: 5,
        totalTokens: 8,
      );

      const warnings = [
        CallWarning(
          code: 'TEST_WARNING',
          message: 'Test warning message',
        ),
      ];

      final metadata = <String, dynamic>{
        'provider': 'test-provider',
        'model': 'test-model',
        'request': {'path': '/v1/test'},
        'response': {'status': 200},
        'custom': 'value',
      };

      final response = _MockChatResponse(
        text: 'final text',
        toolCalls: [toolCall],
        thinking: 'thinking...',
        usage: usage,
        warnings: warnings,
        metadata: metadata,
      );

      final source = Stream<ChatStreamEvent>.fromIterable([
        const TextDeltaEvent('final '),
        const TextDeltaEvent('text'),
        CompletionEvent(response),
      ]);

      final parts = await adaptStreamText(source).toList();

      final finish = parts.whereType<StreamFinish>().single;
      final result = finish.result;

      expect(result.text, equals('final text'));
      expect(result.thinking, equals('thinking...'));
      expect(result.toolCalls, isNotNull);
      expect(result.toolCalls, hasLength(1));
      expect(result.toolCalls!.single.id, equals('call_1'));
      expect(result.usage, equals(usage));
      expect(result.warnings, equals(warnings));

      // Metadata should be converted into a CallMetadata instance.
      expect(result.metadata, isNotNull);
      expect(result.metadata!.provider, equals('test-provider'));
      expect(result.metadata!.model, equals('test-model'));
      expect(result.metadata!.request?['path'], equals('/v1/test'));
      expect(result.metadata!.response?['status'], equals(200));
      expect(
        result.metadata!.providerMetadata?['custom'],
        equals('value'),
      );

      // Raw response should be preserved.
      expect(result.rawResponse, same(response));
    });

    test('handles completion without any text deltas', () async {
      final response = _MockChatResponse(text: 'only completion');

      final source = Stream<ChatStreamEvent>.fromIterable([
        CompletionEvent(response),
      ]);

      final parts = await adaptStreamText(source).toList();

      expect(parts.whereType<StreamTextStart>(), isEmpty);
      expect(parts.whereType<StreamTextDelta>(), isEmpty);
      expect(parts.whereType<StreamTextEnd>(), isEmpty);

      final finish = parts.whereType<StreamFinish>().single;
      expect(finish.result.text, equals('only completion'));
    });

    test('emits StreamThinkingDelta for thinking events', () async {
      final source = Stream<ChatStreamEvent>.fromIterable([
        const ThinkingDeltaEvent('step 1'),
        const ThinkingDeltaEvent(' step 2'),
        CompletionEvent(_MockChatResponse(text: 'done')),
      ]);

      final parts = await adaptStreamText(source).toList();

      final thinkingParts = parts.whereType<StreamThinkingDelta>().toList();
      expect(thinkingParts, hasLength(2));
      expect(
        thinkingParts.map((p) => p.delta).join(),
        equals('step 1 step 2'),
      );
    });

    test('filters out empty text deltas', () async {
      final response = _MockChatResponse(text: 'Hello, world!');

      final source = Stream<ChatStreamEvent>.fromIterable([
        const TextDeltaEvent(''),
        const TextDeltaEvent('Hello'),
        const TextDeltaEvent(''),
        CompletionEvent(response),
      ]);

      final parts = await adaptStreamText(source).toList();

      final textStarts = parts.whereType<StreamTextStart>().toList();
      final textDeltas = parts.whereType<StreamTextDelta>().toList();
      final textEnds = parts.whereType<StreamTextEnd>().toList();

      expect(textStarts, hasLength(1));
      expect(textEnds, hasLength(1));

      // Only the non-empty delta should be emitted.
      expect(textDeltas, hasLength(1));
      expect(textDeltas.single.delta, equals('Hello'));
    });
  });
}
