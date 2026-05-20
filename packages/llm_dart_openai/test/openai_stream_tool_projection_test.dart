import 'package:llm_dart_openai/src/tools/openai_stream_tool_projection.dart';
import 'package:llm_dart_openai/src/common/openai_streaming_support.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI stream tool projection', () {
    test('accumulates indexed tool deltas and projects input events once', () {
      final state = OpenAIStreamState();
      const metadata = ProviderMetadata({
        'openai': {
          'index': 0,
        },
      });

      final firstDelta = consumeOpenAIToolCallDelta(
        state: state,
        index: 0,
        fallbackToolCallId: 'tool_0',
        toolCallId: 'call_1',
        toolName: 'weather',
        argumentsDelta: '{"city":',
      );
      final secondDelta = consumeOpenAIToolCallDelta(
        state: state,
        index: 0,
        fallbackToolCallId: 'tool_0',
        argumentsDelta: '"Paris"}',
      );

      expect(state.hasToolCalls, isTrue);
      expect(firstDelta.index, 0);
      expect(secondDelta.toolState, same(firstDelta.toolState));

      final startEvent = maybeCreateOpenAIToolInputStartEvent(
        toolState: firstDelta.toolState,
        fallbackToolCallId: 'tool_0',
        metadata: () => metadata,
      );
      expect(startEvent, isNotNull);
      expect(startEvent!.toolCallId, 'call_1');
      expect(startEvent.toolName, 'weather');
      expect(startEvent.providerMetadata, same(metadata));
      expect(
        maybeCreateOpenAIToolInputStartEvent(
          toolState: firstDelta.toolState,
          fallbackToolCallId: 'tool_0',
          metadata: () => metadata,
        ),
        isNull,
      );

      final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
        toolState: firstDelta.toolState,
        fallbackToolCallId: 'tool_0',
        delta: firstDelta.argumentsDelta,
        metadata: () => metadata,
      );
      expect(deltaEvent, isNotNull);
      expect(deltaEvent!.toolCallId, 'call_1');
      expect(deltaEvent.delta, '{"city":');

      final input = resolveOpenAIStreamToolInput(
        toolState: firstDelta.toolState,
        fallbackToolCallId: 'tool_0',
      );
      expect(input.decodeError, isNull);
      expect(input.decodedInput, {
        'city': 'Paris',
      });

      final endEvent = maybeCreateOpenAIToolInputEndEvent(
        toolState: firstDelta.toolState,
        fallbackToolCallId: 'tool_0',
        metadata: () => metadata,
      );
      expect(endEvent, isNotNull);
      expect(endEvent!.toolCallId, 'call_1');
      expect(
        maybeCreateOpenAIToolInputEndEvent(
          toolState: firstDelta.toolState,
          fallbackToolCallId: 'tool_0',
          metadata: () => metadata,
        ),
        isNull,
      );
    });

    test('creates ephemeral state for Responses chunks without output index',
        () {
      final state = OpenAIStreamState();

      final toolState = resolveOpenAIStreamToolCallState(
        state: state,
        index: null,
        fallbackToolCallId: 'item_1',
        toolCallId: 'call_1',
        toolName: 'web_search',
        title: 'Search',
        createEphemeralWhenIndexMissing: true,
      );

      expect(toolState.index, -1);
      expect(toolState.resolveToolCallId('item_1'), 'call_1');
      expect(toolState.resolveToolName(), 'web_search');
      expect(toolState.title, 'Search');
      expect(state.toolCalls.length, 0);
      expect(state.hasToolCalls, isTrue);
    });

    test('projects invalid tool input into an error event', () {
      final state = OpenAIStreamState();
      final delta = consumeOpenAIToolCallDelta(
        state: state,
        index: 0,
        fallbackToolCallId: 'tool_0',
        toolCallId: 'call_bad',
        toolName: 'weather',
        argumentsDelta: '{"city":',
      );

      final input = resolveOpenAIStreamToolInput(
        toolState: delta.toolState,
        fallbackToolCallId: 'tool_0',
      );
      expect(input.decodeError, isNotNull);

      final event = createOpenAIToolInputErrorEvent(
        input: input,
        providerExecuted: true,
        isDynamic: true,
        metadata: () => null,
      );

      expect(event.toolCallId, 'call_bad');
      expect(event.toolName, 'weather');
      expect(event.input, '{"city":');
      expect(
        event.errorText,
        contains('Invalid JSON tool arguments for "weather"'),
      );
      expect(event.providerExecuted, isTrue);
      expect(event.isDynamic, isTrue);
    });
  });
}
