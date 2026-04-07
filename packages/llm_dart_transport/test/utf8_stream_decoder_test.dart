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

    test('flush clears malformed trailing bytes gracefully', () {
      final decoder = Utf8StreamDecoder();

      expect(decoder.decode(const [0xF0, 0x9F]), '');
      expect(decoder.hasBufferedBytes, isTrue);
      expect(decoder.flush(), '');
      expect(decoder.hasBufferedBytes, isFalse);
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
}
