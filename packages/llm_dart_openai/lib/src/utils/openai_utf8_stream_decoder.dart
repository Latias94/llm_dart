import 'dart:convert';

/// A UTF-8 stream decoder that handles incomplete byte sequences gracefully.
class Utf8StreamDecoder {
  final List<int> _buffer = <int>[];

  String decode(List<int> chunk) {
    if (chunk.isEmpty) return '';

    _buffer.addAll(chunk);

    int lastCompleteIndex = _findLastCompleteUtf8Index(_buffer);
    if (lastCompleteIndex == -1) {
      return '';
    }

    final completeBytes = _buffer.sublist(0, lastCompleteIndex + 1);
    final remainingBytes = _buffer.sublist(lastCompleteIndex + 1);
    _buffer
      ..clear()
      ..addAll(remainingBytes);

    try {
      return utf8.decode(completeBytes);
    } catch (_) {
      _buffer.clear();
      return '';
    }
  }

  String flush() {
    if (_buffer.isEmpty) return '';

    try {
      final result = utf8.decode(_buffer);
      _buffer.clear();
      return result;
    } catch (_) {
      _buffer.clear();
      return '';
    }
  }

  void reset() {
    _buffer.clear();
  }

  bool get hasBufferedBytes => _buffer.isNotEmpty;

  int get bufferedByteCount => _buffer.length;

  int _findLastCompleteUtf8Index(List<int> bytes) {
    if (bytes.isEmpty) return -1;

    for (int i = bytes.length - 1; i >= 0; i--) {
      final byte = bytes[i];

      if (byte <= 0x7F) {
        return i;
      }

      if ((byte & 0xC0) == 0xC0) {
        int expectedLength;
        if ((byte & 0xE0) == 0xC0) {
          expectedLength = 2;
        } else if ((byte & 0xF0) == 0xE0) {
          expectedLength = 3;
        } else if ((byte & 0xF8) == 0xF0) {
          expectedLength = 4;
        } else {
          continue;
        }

        int availableLength = bytes.length - i;
        if (availableLength >= expectedLength) {
          bool isValid = true;
          for (int j = 1; j < expectedLength; j++) {
            if (i + j >= bytes.length || (bytes[i + j] & 0xC0) != 0x80) {
              isValid = false;
              break;
            }
          }

          if (isValid) {
            return i + expectedLength - 1;
          }
        }

        if (i > 0) {
          return _findLastCompleteUtf8Index(bytes.sublist(0, i));
        } else {
          return -1;
        }
      }
    }

    return -1;
  }
}
