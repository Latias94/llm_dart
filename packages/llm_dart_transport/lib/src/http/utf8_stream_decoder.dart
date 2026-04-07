import 'dart:convert';

/// A UTF-8 stream decoder that handles incomplete byte sequences gracefully.
///
/// This decoder buffers incomplete UTF-8 byte sequences and only emits
/// complete, valid UTF-8 strings. This prevents FormatException when
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
/// // Don't forget to flush any remaining bytes
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

  /// Flush any remaining buffered bytes.
  ///
  /// Call this when the stream ends to get any remaining partial data.
  /// This may throw a FormatException if the buffer contains invalid UTF-8.
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

  /// Clear the internal buffer.
  void reset() {
    _buffer.clear();
  }

  /// Check if there are buffered bytes waiting for completion.
  bool get hasBufferedBytes => _buffer.isNotEmpty;

  /// Get the number of buffered bytes.
  int get bufferedByteCount => _buffer.length;

  /// Find the index of the last complete UTF-8 character in the byte array.
  ///
  /// Returns -1 if no complete characters are found.
  int _findLastCompleteUtf8Index(List<int> bytes) {
    if (bytes.isEmpty) return -1;

    for (var index = bytes.length - 1; index >= 0; index -= 1) {
      final byte = bytes[index];

      if (byte <= 0x7F) {
        return index;
      }

      if ((byte & 0xC0) == 0xC0) {
        final expectedLength = switch (byte) {
          _ when (byte & 0xE0) == 0xC0 => 2,
          _ when (byte & 0xF0) == 0xE0 => 3,
          _ when (byte & 0xF8) == 0xF0 => 4,
          _ => -1,
        };

        if (expectedLength == -1) {
          continue;
        }

        final availableLength = bytes.length - index;
        if (availableLength >= expectedLength) {
          var isValid = true;
          for (var offset = 1; offset < expectedLength; offset += 1) {
            if (index + offset >= bytes.length ||
                (bytes[index + offset] & 0xC0) != 0x80) {
              isValid = false;
              break;
            }
          }

          if (isValid) {
            return index + expectedLength - 1;
          }
        }

        if (index > 0) {
          return _findLastCompleteUtf8Index(bytes.sublist(0, index));
        }
        return -1;
      }
    }

    return -1;
  }
}

/// Extension to make it easier to use Utf8StreamDecoder with streams.
extension Utf8StreamDecoderExtension on Stream<List<int>> {
  /// Transform a byte stream into a UTF-8 string stream with proper handling
  /// of incomplete multi-byte sequences.
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
