import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('Utf8StreamDecoder', () {
    test('buffers incomplete multi-byte sequences until complete', () {
      final decoder = Utf8StreamDecoder();
      final bytes = utf8.encode('你好世界');

      expect(decoder.decode(bytes.sublist(0, 4)), '你');
      expect(decoder.decode(bytes.sublist(4)), '好世界');
    });

    test('tracks incomplete trailing bytes until flush', () {
      final decoder = Utf8StreamDecoder();

      expect(decoder.decode(const [0xF0, 0x9F]), '');
      expect(decoder.hasBufferedBytes, isTrue);
      expect(decoder.bufferedByteCount, 2);
      expect(() => decoder.flush(), throwsA(isA<FormatException>()));
      expect(decoder.hasBufferedBytes, isFalse);
    });

    test('can replace malformed trailing bytes when requested', () {
      final decoder = Utf8StreamDecoder(allowMalformed: true);

      expect(decoder.decode(const [0xF0, 0x9F]), '');
      expect(decoder.flush(), '\u{FFFD}');
      expect(decoder.hasBufferedBytes, isFalse);
    });

    test('reset clears buffered bytes and keeps the decoder reusable', () {
      final decoder = Utf8StreamDecoder();

      expect(decoder.decode(const [0xE4, 0xB8]), '');
      expect(decoder.hasBufferedBytes, isTrue);
      decoder.reset();

      expect(decoder.hasBufferedBytes, isFalse);
      expect(decoder.decode(utf8.encode('ok')), 'ok');
      expect(decoder.flush(), '');
    });
  });

  test('Utf8StreamDecoderExtension rebuilds split UTF-8 chunks', () async {
    final bytes = utf8.encode('Hello 你好 World 🌍');

    Stream<List<int>> byteStream() async* {
      for (var index = 0; index < bytes.length; index += 3) {
        final end = index + 3 < bytes.length ? index + 3 : bytes.length;
        yield bytes.sublist(index, end);
      }
    }

    final result = await byteStream().decodeUtf8Stream().join();
    expect(result, 'Hello 你好 World 🌍');
  });

  test('Utf8StreamDecoderExtension surfaces malformed UTF-8 by default',
      () async {
    final stream = Stream<List<int>>.fromIterable([
      const [0xF0, 0x9F],
    ]);

    expect(stream.decodeUtf8Stream(), emitsError(isA<FormatException>()));
  });

  test('Utf8StreamDecoderExtension can replace malformed UTF-8', () async {
    final result = await Stream<List<int>>.fromIterable([
      const [0xF0, 0x9F],
    ]).decodeUtf8Stream(allowMalformed: true).join();

    expect(result, '\u{FFFD}');
  });
}
