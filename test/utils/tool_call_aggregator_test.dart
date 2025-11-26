import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ToolCallAggregator', () {
    test('should return delta as-is for first call', () {
      final aggregator = ToolCallAggregator();

      final delta = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '',
        ),
      );

      final aggregated = aggregator.addDelta(delta);

      expect(aggregated.id, equals('call_1'));
      expect(aggregated.function.name, equals('get_weather'));
      expect(aggregated.function.arguments, equals(''));

      final completed = aggregator.completedCalls;
      expect(completed.length, equals(1));
      expect(completed.first.function.name, equals('get_weather'));
    });

    test('should merge multiple deltas for same id', () {
      final aggregator = ToolCallAggregator();

      final first = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '',
        ),
      );

      final second = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: '',
          arguments: '{"location": "',
        ),
      );

      final third = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: '',
          arguments: 'Paris"}',
        ),
      );

      aggregator.addDelta(first);
      aggregator.addDelta(second);
      final aggregated = aggregator.addDelta(third);

      expect(aggregated.id, equals('call_1'));
      expect(aggregated.callType, equals('function'));
      expect(aggregated.function.name, equals('get_weather'));
      expect(
        aggregated.function.arguments,
        equals('{"location": "Paris"}'),
      );

      final completed = aggregator.completedCalls;
      expect(completed.length, equals(1));
      expect(completed.first.function.name, equals('get_weather'));
      expect(
        completed.first.function.arguments,
        equals('{"location": "Paris"}'),
      );
    });

    test('completedCalls should ignore entries without name', () {
      final aggregator = ToolCallAggregator();

      final delta = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: '',
          arguments: '{"partial": true}',
        ),
      );

      aggregator.addDelta(delta);
      final completed = aggregator.completedCalls;

      expect(completed, isEmpty);
    });

    test('clear should reset internal state', () {
      final aggregator = ToolCallAggregator();

      final delta = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"location": "Paris"}',
        ),
      );

      aggregator.addDelta(delta);
      expect(aggregator.completedCalls, isNotEmpty);

      aggregator.clear();
      expect(aggregator.completedCalls, isEmpty);
    });
  });
}
