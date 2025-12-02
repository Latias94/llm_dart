import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  group('SSELineBuffer', () {
    test('returns single line for simple chunk', () {
      final buffer = SSELineBuffer();

      final lines = buffer.addChunk('data: hello\n');

      expect(lines, ['data: hello']);
      // Second call with empty input should not change state
      expect(buffer.addChunk(''), isEmpty);
    });

    test('handles multiple lines in one chunk', () {
      final buffer = SSELineBuffer();

      final lines = buffer.addChunk('data: one\ndata: two\n');

      expect(lines, ['data: one', 'data: two']);
    });

    test('handles line split across chunks', () {
      final buffer = SSELineBuffer();

      final first = buffer.addChunk('data: par');
      final second = buffer.addChunk('tial\n');

      expect(first, isEmpty);
      expect(second, ['data: partial']);
    });

    test('handles trailing partial line with multiple complete lines', () {
      final buffer = SSELineBuffer();

      final first = buffer.addChunk('data: one\npartial');
      final second = buffer.addChunk(' line\n');

      expect(first, ['data: one']);
      expect(second, ['partial line']);
    });

    test('clear resets internal buffer', () {
      final buffer = SSELineBuffer();

      buffer.addChunk('data: one');
      buffer.clear();
      final lines = buffer.addChunk('data: two\n');

      expect(lines, ['data: two']);
    });
  });
}
