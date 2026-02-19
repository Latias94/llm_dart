import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ToolCallAggregator', () {
    test('should return delta as-is for first call', () {
      final aggregator = ToolCallAggregator();

      final delta = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'get_weather',
        input: '',
      );

      final aggregated = aggregator.addDelta(delta);

      expect(aggregated.toolCallId, equals('call_1'));
      expect(aggregated.toolName, equals('get_weather'));
      expect(aggregated.input, equals(''));

      final completed = aggregator.completedCalls;
      expect(completed.length, equals(1));
      expect(completed.first.toolName, equals('get_weather'));
    });

    test('should merge multiple deltas for same id', () {
      final aggregator = ToolCallAggregator();

      final first = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'get_weather',
        input: '',
      );

      final second = V3ToolCall(
        toolCallId: 'call_1',
        toolName: '',
        input: '{"location": "',
      );

      final third = V3ToolCall(
        toolCallId: 'call_1',
        toolName: '',
        input: 'Paris"}',
      );

      aggregator.addDelta(first);
      aggregator.addDelta(second);
      final aggregated = aggregator.addDelta(third);

      expect(aggregated.toolCallId, equals('call_1'));
      expect(aggregated.toolName, equals('get_weather'));
      expect(
        aggregated.input,
        equals('{"location": "Paris"}'),
      );

      final completed = aggregator.completedCalls;
      expect(completed.length, equals(1));
      expect(completed.first.toolName, equals('get_weather'));
      expect(
        completed.first.input,
        equals('{"location": "Paris"}'),
      );
    });

    test('completedCalls should ignore entries without name', () {
      final aggregator = ToolCallAggregator();

      final delta = V3ToolCall(
        toolCallId: 'call_1',
        toolName: '',
        input: '{"partial": true}',
      );

      aggregator.addDelta(delta);
      final completed = aggregator.completedCalls;

      expect(completed, isEmpty);
    });

    test('clear should reset internal state', () {
      final aggregator = ToolCallAggregator();

      final delta = V3ToolCall(
        toolCallId: 'call_1',
        toolName: 'get_weather',
        input: '{"location": "Paris"}',
      );

      aggregator.addDelta(delta);
      expect(aggregator.completedCalls, isNotEmpty);

      aggregator.clear();
      expect(aggregator.completedCalls, isEmpty);
    });
  });
}
