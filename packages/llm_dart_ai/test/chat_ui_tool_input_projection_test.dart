import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiToolInputProjection', () {
    test('streams input parts and merges call provider metadata', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator
        ..apply(
          ToolInputStartEvent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            providerExecuted: true,
            isDynamic: true,
            title: 'Weather',
            providerMetadata: ProviderMetadata.forNamespace(
              'test',
              {'phase': 'start'},
            ),
          ),
        )
        ..apply(
          ToolInputDeltaEvent(
            toolCallId: 'tool-1',
            delta: '{"city":"Par',
            providerMetadata: ProviderMetadata.forNamespace(
              'test',
              {'delta': 1},
            ),
          ),
        )
        ..apply(
          ToolInputDeltaEvent(
            toolCallId: 'tool-1',
            delta: 'is"}',
            providerMetadata: ProviderMetadata.forNamespace(
              'other',
              {'delta': 2},
            ),
          ),
        );

      var tool = accumulator.message.parts.single as ToolUiPart;
      expect(tool.state, ToolUiPartState.inputStreaming);
      expect(tool.input, {'city': 'Paris'});
      expect(tool.inputText, '{"city":"Paris"}');
      expect(tool.providerExecuted, isTrue);
      expect(tool.isDynamic, isTrue);
      expect(tool.title, 'Weather');
      expect(tool.callProviderMetadata?.namespace('test'), {
        'phase': 'start',
        'delta': 1,
      });
      expect(tool.callProviderMetadata?.namespace('other'), {'delta': 2});

      accumulator.apply(
        ToolInputEndEvent(
          toolCallId: 'tool-1',
          providerMetadata: ProviderMetadata.forNamespace(
            'test',
            {'phase': 'end'},
          ),
        ),
      );

      tool = accumulator.message.parts.single as ToolUiPart;
      expect(tool.state, ToolUiPartState.inputAvailable);
      expect(tool.input, {'city': 'Paris'});
      expect(tool.inputText, '{"city":"Paris"}');
      expect(tool.callProviderMetadata?.namespace('test'), {
        'phase': 'end',
        'delta': 1,
      });
      expect(tool.callProviderMetadata?.namespace('other'), {'delta': 2});
    });

    test('keeps malformed streamed input text on input error', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator
        ..apply(
          const ToolInputStartEvent(
            toolCallId: 'tool-1',
            toolName: 'weather',
          ),
        )
        ..apply(
          const ToolInputDeltaEvent(
            toolCallId: 'tool-1',
            delta: '{"city":',
          ),
        )
        ..apply(
          const ToolInputErrorEvent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            errorText: 'Invalid input',
          ),
        );

      final tool = accumulator.message.parts.single as ToolUiPart;
      expect(tool.state, ToolUiPartState.outputError);
      expect(tool.input, '{"city":');
      expect(tool.inputText, '{"city":');
      expect(tool.output, isNull);
      expect(tool.toolOutput, isNull);
      expect(tool.errorText, 'Invalid input');
    });

    test('tool call replaces a partial streamed input', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator
        ..apply(
          const ToolInputStartEvent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            title: 'Streaming Weather',
          ),
        )
        ..apply(
          const ToolInputDeltaEvent(
            toolCallId: 'tool-1',
            delta: '{"city":"Par',
          ),
        )
        ..apply(
          ToolCallEvent(
            toolCall: const ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
              input: {'city': 'Paris'},
              title: 'Final Weather',
            ),
          ),
        );

      final tool = accumulator.message.parts.single as ToolUiPart;
      expect(tool.state, ToolUiPartState.inputAvailable);
      expect(tool.input, {'city': 'Paris'});
      expect(tool.inputText, '{"city":"Par');
      expect(tool.title, 'Final Weather');
    });
  });
}
