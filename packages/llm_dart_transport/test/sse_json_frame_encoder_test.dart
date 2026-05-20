import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('SseJsonFrameEncoder writes SSE metadata and JSON data', () async {
    const encoder = SseJsonFrameEncoder();

    final frame = encoder.encodeFrame(
      const {
        'ok': true,
      },
      event: 'message',
      id: 'frame-1',
      retryMilliseconds: 250,
    );

    expect(
      frame,
      'event: message\n'
      'id: frame-1\n'
      'retry: 250\n'
      'data: {"ok":true}\n'
      '\n',
    );

    final decoded = await const DefaultSseDecoder()
        .decode(Stream<String>.value(frame))
        .toList();

    expect(decoded, hasLength(1));
    expect(decoded.single.event, 'message');
    expect(decoded.single.id, 'frame-1');
    expect(decoded.single.retryMilliseconds, 250);
    expect(decoded.single.data, '{"ok":true}');
  });

  test('SseJsonFrameEncoder supports multiline JSON encoder output', () async {
    const encoder = SseJsonFrameEncoder(
      jsonEncoder: JsonEncoder.withIndent('  '),
    );

    final payloads = await const SseJsonChunkParser()
        .parse(
          Stream<List<int>>.value(
            encoder.encodeFrameBytes(
              const {
                'nested': {
                  'ok': true,
                },
              },
            ),
          ),
        )
        .toList();

    expect(
      payloads,
      const [
        {
          'nested': {
            'ok': true,
          },
        },
      ],
    );
  });

  test('SseJsonFrameEncoder appends optional done frame for streams', () async {
    const encoder = SseJsonFrameEncoder();

    final byteChunks = await encoder
        .encodeFrameStream(
          Stream<Object?>.fromIterable([
            const {
              'type': 'text-delta',
              'delta': 'hello',
            },
          ]),
          includeDoneFrame: true,
        )
        .toList();

    final frames = await const DefaultSseDecoder()
        .decode(utf8.decoder.bind(Stream<List<int>>.fromIterable(byteChunks)))
        .toList();

    expect(frames, hasLength(2));
    expect(frames.first.data, '{"type":"text-delta","delta":"hello"}');
    expect(frames.last.data, '[DONE]');

    final payloads = await const SseJsonChunkParser()
        .parse(Stream<List<int>>.fromIterable(byteChunks))
        .toList();
    expect(payloads, hasLength(1));
    expect(payloads.single['type'], 'text-delta');
  });
}
