import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test(
      'decodeJsonSseLanguageModelStream emits raw chunks before decoded events',
      () async {
    final events = await decodeJsonSseLanguageModelStream<_TextState>(
      stream: Stream.fromIterable([
        utf8.encode('data: {"delta":"hel"}\n\n'),
        utf8.encode('data: {"delta":"lo"}\n\n'),
        utf8.encode('data: [DONE]\n\n'),
      ]),
      state: _TextState(),
      includeRawChunks: true,
      sourceName: 'test stream',
      decodeChunk: (chunk, state) {
        final delta = chunk['delta'] as String;
        state.text.write(delta);
        return [
          TextDeltaEvent(
            id: 'text',
            delta: delta,
          ),
        ];
      },
      finish: (state) => [
        FinishEvent(
          finishReason: FinishReason.stop,
          rawFinishReason: state.text.toString(),
        ),
      ],
    ).toList();

    expect(events, hasLength(5));
    expect(events[0], isA<RawChunkEvent>());
    expect((events[0] as RawChunkEvent).raw, const {'delta': 'hel'});
    expect(events[1], isA<TextDeltaEvent>());
    expect((events[1] as TextDeltaEvent).delta, 'hel');
    expect(events[2], isA<RawChunkEvent>());
    expect((events[2] as RawChunkEvent).raw, const {'delta': 'lo'});
    expect(events[3], isA<TextDeltaEvent>());
    expect((events[3] as TextDeltaEvent).delta, 'lo');
    expect(events[4], isA<FinishEvent>());
    expect((events[4] as FinishEvent).rawFinishReason, 'hello');
  });

  test('decodeJsonSseLanguageModelStream forwards source names to parse errors',
      () {
    expect(
      decodeJsonSseLanguageModelStream<Object?>(
        stream: Stream.fromIterable([
          utf8.encode('data: ["not","object"]\n\n'),
        ]),
        state: null,
        sourceName: 'provider stream',
        decodeChunk: (_, __) => const [],
      ),
      emitsError(
        isA<TransportResponseFormatException>().having(
          (error) => error.message,
          'message',
          contains('provider stream API returned JSON that is not an object'),
        ),
      ),
    );
  });
}

final class _TextState {
  final text = StringBuffer();
}
