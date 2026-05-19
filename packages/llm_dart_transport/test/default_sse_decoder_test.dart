import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('DefaultSseDecoder rebuilds split SSE frames', () async {
    final frames = await _decode([
      'id: 1\nevent: message\ndata: hel',
      'lo\ndata: world\n\n',
    ]);

    expect(frames, hasLength(1));
    expect(frames.single.id, '1');
    expect(frames.single.event, 'message');
    expect(frames.single.data, 'hello\nworld');
  });

  test('DefaultSseDecoder preserves CRLF split across chunks', () async {
    final frames = await _decode([
      'data: {"a":1}\r',
      '\n',
      'data: {"b":2}\r',
      '\n',
      '\r',
      '\n',
    ]);

    expect(frames, hasLength(1));
    expect(frames.single.data, '{"a":1}\n{"b":2}');
  });

  test('DefaultSseDecoder handles BOM, comments, id, retry, and empty data',
      () async {
    final frames = await _decode([
      '\uFEFF: keepalive\r\n',
      'id: first\r\n',
      'event: update\r\n',
      'retry: 2500\r\n',
      'data:\r\n',
      'data: payload\r\n',
      '\r\n',
      'id: ignore\u0000this\r\n',
      'data: next\r\n',
      '\r\n',
    ]);

    expect(frames, hasLength(2));
    expect(frames.first.id, 'first');
    expect(frames.first.event, 'update');
    expect(frames.first.retryMilliseconds, 2500);
    expect(frames.first.data, '\npayload');
    expect(frames.last.id, 'first');
    expect(frames.last.data, 'next');
  });

  test('DefaultSseDecoder flushes trailing frame without blank line', () async {
    final frames = await _decode([
      'event: message\n',
      'data: final',
    ]);

    expect(frames, hasLength(1));
    expect(frames.single.event, 'message');
    expect(frames.single.data, 'final');
  });
}

Future<List<SseFrame>> _decode(List<String> chunks) {
  return const DefaultSseDecoder().decode(Stream.fromIterable(chunks)).toList();
}
