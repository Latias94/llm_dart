import 'package:llm_dart_ai/src/common/tool_input_stream_store.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ToolInputStreamStore', () {
    test('tracks provider metadata across streamed input chunks', () {
      final store = ToolInputStreamStore(
        createMissingInputError: missingToolInputStateError,
      );

      store.start(
        const ToolInputStartEvent(
          toolCallId: 'tool-1',
          toolName: 'weather',
          providerMetadata: ProviderMetadata({
            'test': {
              'phase': 'start',
            },
          }),
        ),
      );
      store.appendDelta(
        const ToolInputDeltaEvent(
          toolCallId: 'tool-1',
          delta: '{"city":"Paris"}',
          providerMetadata: ProviderMetadata({
            'test': {
              'delta': true,
            },
          }),
        ),
      );

      final partial = store.end(
        const ToolInputEndEvent(toolCallId: 'tool-1'),
      );

      expect(partial.input, {'city': 'Paris'});
      expect(partial.providerMetadata?.toJsonMap(), {
        'test': {
          'phase': 'start',
          'delta': true,
        },
      });
      expect(store.get('tool-1'), isNull);
    });

    test('hydrates from an existing streaming UI part', () {
      final store = ToolInputStreamStore(
        createMissingInputError: missingToolInputStateError,
      )..hydrate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          providerExecuted: true,
          isDynamic: true,
          title: 'Weather',
          input: {'city': 'Paris'},
        );

      final partial = store.get('tool-1')!;

      expect(partial.text, '{"city":"Paris"}');
      expect(partial.providerExecuted, isTrue);
      expect(partial.isDynamic, isTrue);
      expect(partial.title, 'Weather');
    });

    test('uses caller-provided missing input error', () {
      final store = ToolInputStreamStore(
        createMissingInputError: (toolCallId) => FormatException(
          'missing $toolCallId',
        ),
      );

      expect(
        () => store.appendDelta(
          const ToolInputDeltaEvent(
            toolCallId: 'missing',
            delta: '{}',
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'missing missing',
          ),
        ),
      );
    });
  });
}
