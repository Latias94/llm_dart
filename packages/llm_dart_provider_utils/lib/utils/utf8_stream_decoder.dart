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

    // Add new bytes to buffer
    _buffer.addAll(chunk);

    // Find the last complete UTF-8 sequence
    int lastCompleteIndex = _findLastCompleteUtf8Index(_buffer);

    if (lastCompleteIndex == -1) {
      // No complete sequences, keep buffering
      return '';
    }

    // Extract complete bytes for decoding
    final completeBytes = _buffer.sublist(0, lastCompleteIndex + 1);

    // Keep incomplete bytes for next chunk
    final remainingBytes = _buffer.sublist(lastCompleteIndex + 1);
    _buffer.clear();
    _buffer.addAll(remainingBytes);

    try {
      return utf8.decode(completeBytes);
    } catch (e) {
      // This shouldn't happen with our logic, but handle gracefully
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
    } catch (e) {
      // Invalid UTF-8 sequence, clear buffer and return empty
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

    // Start from the end and work backwards
    for (int i = bytes.length - 1; i >= 0; i--) {
      final byte = bytes[i];

      // ASCII character (0xxxxxxx) - always complete
      if (byte <= 0x7F) {
        return i;
      }

      // Start of multi-byte sequence (11xxxxxx)
      if ((byte & 0xC0) == 0xC0) {
        // Determine expected sequence length
        int expectedLength;
        if ((byte & 0xE0) == 0xC0) {
          expectedLength = 2; // 110xxxxx
        } else if ((byte & 0xF0) == 0xE0) {
          expectedLength = 3; // 1110xxxx
        } else if ((byte & 0xF8) == 0xF0) {
          expectedLength = 4; // 11110xxx
        } else {
          // Invalid start byte, skip
          continue;
        }

        // Check if we have enough bytes for complete sequence
        int availableLength = bytes.length - i;
        if (availableLength >= expectedLength) {
          // Verify all continuation bytes are valid
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

        // Incomplete sequence, check previous character
        if (i > 0) {
          return _findLastCompleteUtf8Index(bytes.sublist(0, i));
        } else {
          return -1;
        }
      }

      // Continuation byte (10xxxxxx) - keep looking backwards
    }

    return -1;
  }
}

/// Extension to make it easier to use Utf8StreamDecoder with streams
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

    // Flush any remaining bytes
    final remaining = decoder.flush();
    if (remaining.isNotEmpty) {
      yield remaining;
    }
  }
}
