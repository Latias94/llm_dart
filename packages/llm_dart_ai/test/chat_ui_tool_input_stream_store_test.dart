import 'package:llm_dart_ai/src/ui/chat_ui_tool_input_stream_store.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiToolInputStreamStore', () {
    test('hydrates streaming tool input from an existing UI part', () {
      final store = ChatUiToolInputStreamStore()
        ..hydrate(
          const ToolUiPart(
            toolCallId: 'tool-1',
            toolName: 'weather',
            state: ToolUiPartState.inputStreaming,
            inputText: '{"city":"Par',
            providerExecuted: true,
            isDynamic: true,
            title: 'Weather',
          ),
        );

      final partial = store.get('tool-1')!;

      expect(partial.toolName, 'weather');
      expect(partial.text, '{"city":"Par');
      expect(partial.providerExecuted, isTrue);
      expect(partial.isDynamic, isTrue);
      expect(partial.title, 'Weather');
    });

    test('tracks start delta and end lifecycle', () {
      final store = ChatUiToolInputStreamStore();

      store.start(
        const ToolInputStartEvent(
          toolCallId: 'tool-1',
          toolName: 'weather',
        ),
      );
      final partial = store.appendDelta(
        const ToolInputDeltaEvent(
          toolCallId: 'tool-1',
          delta: '{"city":"Paris"}',
        ),
      );

      expect(partial.input, {'city': 'Paris'});

      final ended = store.end(
        const ToolInputEndEvent(toolCallId: 'tool-1'),
      );

      expect(ended.input, {'city': 'Paris'});
      expect(store.get('tool-1'), isNull);
    });

    test('removes partial input on explicit fail', () {
      final store = ChatUiToolInputStreamStore()
        ..start(
          const ToolInputStartEvent(
            toolCallId: 'tool-1',
            toolName: 'weather',
          ),
        )
        ..appendDelta(
          const ToolInputDeltaEvent(
            toolCallId: 'tool-1',
            delta: 'not json',
          ),
        );

      final partial = store.fail(
        const ToolInputErrorEvent(
          toolCallId: 'tool-1',
          toolName: 'weather',
          input: 'not json',
          errorText: 'bad input',
        ),
      );

      expect(partial?.text, 'not json');
      expect(store.get('tool-1'), isNull);
    });

    test('throws stream error for missing partial input updates', () {
      final store = ChatUiToolInputStreamStore();

      expect(
        () => store.appendDelta(
          const ToolInputDeltaEvent(
            toolCallId: 'missing',
            delta: '{}',
          ),
        ),
        throwsA(
          isA<ChatUiStreamError>()
              .having(
                  (error) => error.chunkType, 'chunkType', 'tool-input-update')
              .having((error) => error.chunkId, 'chunkId', 'missing'),
        ),
      );
    });
  });
}
