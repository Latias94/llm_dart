import 'dart:convert';

/// A UTF-8 stream decoder that handles incomplete byte sequences gracefully.
///
/// This decoder buffers incomplete UTF-8 byte sequences and only emits
/// complete, valid UTF-8 strings. This prevents [FormatException] when
/// multi-byte characters are split across network chunks.
///
/// Example usage:
/// ```dart
/// final decoder = Utf8StreamDecoder();
///
/// await for (final chunk in byteStream) {
///   final decoded = decoder.decode(chunk);
///   if (decoded.isNotEmpty) {
///     print(decoded);
///   }
/// }
///
/// // Don't forget to flush any remaining bytes.
/// final remaining = decoder.flush();
/// if (remaining.isNotEmpty) {
///   print(remaining);
/// }
/// ```
class Utf8StreamDecoder {
  final List<int> _buffer = <int>[];

  /// Decode a chunk of bytes, returning only complete UTF-8 strings.
  ///
  /// Incomplete UTF-8 sequences are buffered until the next chunk.
  /// Returns an empty string if no complete sequences are available.
  String decode(List<int> chunk) {
    if (chunk.isEmpty) return '';

    _buffer.addAll(chunk);

    final lastCompleteIndex = _findLastCompleteUtf8Index(_buffer);
    if (lastCompleteIndex == -1) {
      // No complete sequences yet, keep buffering.
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
      // This should be rare given our checks, but clear buffer on failure.
      _buffer.clear();
      return '';
    }
  }

  /// Flush any remaining buffered bytes.
  ///
  /// Call this when the stream ends to get any remaining partial data.
  /// Returns an empty string if the buffer is empty or contains invalid UTF-8.
  String flush() {
    if (_buffer.isEmpty) return '';

    try {
      final result = utf8.decode(_buffer);
      _buffer.clear();
      return result;
    } catch (_) {
      // Invalid UTF-8 sequence, clear buffer and return empty.
      _buffer.clear();
      return '';
    }
  }

  /// Clear the internal buffer.
  void reset() {
    _buffer.clear();
  }

  /// Whether there are buffered bytes waiting for completion.
  bool get hasBufferedBytes => _buffer.isNotEmpty;

  /// Number of buffered bytes.
  int get bufferedByteCount => _buffer.length;

  /// Find the index of the last complete UTF-8 character in the byte array.
  ///
  /// Returns -1 if no complete characters are found.
  int _findLastCompleteUtf8Index(List<int> bytes) {
    if (bytes.isEmpty) return -1;

    for (int i = bytes.length - 1; i >= 0; i--) {
      final byte = bytes[i];

      // ASCII character (0xxxxxxx) - always complete.
      if (byte <= 0x7F) {
        return i;
      }

      // Start of multi-byte sequence (11xxxxxx).
      if ((byte & 0xC0) == 0xC0) {
        int expectedLength;
        if ((byte & 0xE0) == 0xC0) {
          expectedLength = 2; // 110xxxxx
        } else if ((byte & 0xF0) == 0xE0) {
          expectedLength = 3; // 1110xxxx
        } else if ((byte & 0xF8) == 0xF0) {
          expectedLength = 4; // 11110xxx
        } else {
          // Invalid start byte, skip.
          continue;
        }

        final availableLength = bytes.length - i;
        if (availableLength >= expectedLength) {
          var isValid = true;
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

        // Not enough bytes or invalid continuation bytes, recurse on prefix.
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

/// Extension to make it easier to use [Utf8StreamDecoder] with byte streams.
extension Utf8StreamDecoderExtension on Stream<List<int>> {
  /// Decode a byte stream into a UTF-8 string stream using [Utf8StreamDecoder].
  Stream<String> decodeUtf8Stream() async* {
    final decoder = Utf8StreamDecoder();

    await for (final chunk in this) {
      final decoded = decoder.decode(chunk);
      if (decoded.isNotEmpty) {
        yield decoded;
      }
    }

    final remaining = decoder.flush();
    if (remaining.isNotEmpty) {
      yield remaining;
    }
  }
}
