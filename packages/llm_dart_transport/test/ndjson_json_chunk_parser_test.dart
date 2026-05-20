import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('NdjsonJsonChunkParser rebuilds split JSON lines', () async {
    const parser = NdjsonJsonChunkParser();

    final chunks = await parser
        .parse(
          Stream.fromIterable([
            utf8.encode('{"a":'),
            utf8.encode('1}\n{"b":2}'),
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

  test('NdjsonJsonChunkParser skips blank lines by default', () async {
    const parser = NdjsonJsonChunkParser();

    final chunks = await parser
        .parse(
          Stream.fromIterable([
            utf8.encode('\n{"ok":true}\n   \n'),
          ]),
        )
        .toList();

    expect(
      chunks,
      const [
        {'ok': true},
      ],
    );
  });

  test('NdjsonJsonChunkParser supports custom line filtering', () async {
    const parser = NdjsonJsonChunkParser();

    final chunks = await parser
        .parse(
          Stream.fromIterable([
            utf8.encode(': keepalive\n{"ok":true}\n'),
          ]),
          shouldSkipLine: (line) => line.startsWith(':'),
        )
        .toList();

    expect(
      chunks,
      const [
        {'ok': true},
      ],
    );
  });

  test('NdjsonJsonChunkParser rejects non-object JSON lines', () {
    const parser = NdjsonJsonChunkParser();

    expect(
      parser.parse(
        Stream.fromIterable([
          utf8.encode('["not","an","object"]\n'),
        ]),
      ),
      emitsError(
        isA<TransportResponseFormatException>().having(
          (error) => error.message,
          'message',
          contains('returned JSON that is not an object'),
        ),
      ),
    );
  });

  test('NdjsonJsonChunkParser surfaces malformed UTF-8 by default', () {
    const parser = NdjsonJsonChunkParser();

    expect(
      parser.parse(
        Stream.fromIterable([
          const [0xF0, 0x9F],
        ]),
      ),
      emitsError(isA<FormatException>()),
    );
  });

  test('NdjsonJsonChunkParser can replace malformed UTF-8', () {
    const parser = NdjsonJsonChunkParser();

    expect(
      parser.parse(
        Stream.fromIterable([
          const [0xF0, 0x9F],
        ]),
        allowMalformedUtf8: true,
      ),
      emitsError(
        isA<TransportResponseFormatException>().having(
          (error) => error.message,
          'message',
          contains('invalid JSON'),
        ),
      ),
    );
  });
}
