import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('SseJsonChunkParser rebuilds split frames and skips [DONE]', () async {
    final parser = const SseJsonChunkParser();

    final chunks = await parser
        .parse(
          Stream.fromIterable([
            utf8.encode('data: {"a":'),
            utf8.encode('1}\n\n'),
            utf8.encode('data: [DONE]\n\n'),
            utf8.encode('data: {"b":2}\n\n'),
          ]),
        )
        .toList();

    expect(
      chunks,
      const [
        {'a': 1},
        {'b': 2},
      ],
    );
  });

  test('SseJsonChunkParser supports custom frame filtering', () async {
    final parser = const SseJsonChunkParser();

    final chunks = await parser
        .parse(
          Stream.fromIterable([
            utf8.encode('event: keepalive\ndata: {"skip":true}\n\n'),
            utf8.encode('event: message\ndata: {"ok":true}\n\n'),
          ]),
          shouldSkipFrame: (frame) => frame.event == 'keepalive',
        )
        .toList();

    expect(
      chunks,
      const [
        {'ok': true},
      ],
    );
  });

  test('SseJsonChunkParser rejects non-object JSON payloads', () async {
    final parser = const SseJsonChunkParser();

    expect(
      parser.parse(
        Stream.fromIterable([
          utf8.encode('data: ["not","an","object"]\n\n'),
        ]),
      ),
      emitsError(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('JSON object SSE payload'),
        ),
      ),
    );
  });
}
