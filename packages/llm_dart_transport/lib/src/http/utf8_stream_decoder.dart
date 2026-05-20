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
  final bool allowMalformed;
  final List<String> _decodedChunks = <String>[];
  final List<int> _pendingUtf8Bytes = <int>[];
  late ByteConversionSink _sink;
  bool _isClosed = false;

  Utf8StreamDecoder({
    this.allowMalformed = false,
  }) {
    _openSink();
  }

  void _openSink() {
    final stringSink = StringConversionSink.from(
      _Utf8DecodedChunkSink(_decodedChunks.add),
    );
    _sink = Utf8Decoder(allowMalformed: allowMalformed)
        .startChunkedConversion(stringSink);
  }

  /// Decode a chunk of bytes, returning only complete UTF-8 strings.
  ///
  /// Incomplete UTF-8 sequences are buffered until the next chunk.
  /// Returns an empty string if no complete sequences are available.
  String decode(List<int> chunk) {
    if (_isClosed) {
      _openSink();
      _isClosed = false;
    }
    if (chunk.isEmpty) {
      return '';
    }

    final trackingBytes = [
      ..._pendingUtf8Bytes,
      ...chunk,
    ];

    _sink.add(chunk);
    _updatePendingUtf8Bytes(trackingBytes);
    return _drainDecodedChunks();
  }

  /// Flush any remaining buffered bytes.
  ///
  /// Call this when the stream ends to get any remaining partial data.
  /// This may throw a FormatException if the buffer contains invalid UTF-8.
  String flush() {
    if (_isClosed) {
      return '';
    }

    try {
      _isClosed = true;
      _sink.close();
      return _drainDecodedChunks();
    } finally {
      _pendingUtf8Bytes.clear();
    }
  }

  String _drainDecodedChunks() {
    if (_decodedChunks.isEmpty) {
      return '';
    }

    final decoded = _decodedChunks.join();
    _decodedChunks.clear();
    return decoded;
  }

  /// Clear the internal buffer.
  void reset() {
    _decodedChunks.clear();
    _pendingUtf8Bytes.clear();
    _openSink();
    _isClosed = false;
  }

  /// Check if there are buffered bytes waiting for completion.
  bool get hasBufferedBytes => _pendingUtf8Bytes.isNotEmpty;

  /// Get the number of buffered bytes.
  int get bufferedByteCount => _pendingUtf8Bytes.length;

  void _updatePendingUtf8Bytes(List<int> bytes) {
    _pendingUtf8Bytes
      ..clear()
      ..addAll(_trailingIncompleteUtf8Sequence(bytes));
  }

  List<int> _trailingIncompleteUtf8Sequence(List<int> bytes) {
    if (bytes.isEmpty) {
      return const [];
    }

    var continuationCount = 0;
    var index = bytes.length - 1;
    while (index >= 0 && _isUtf8ContinuationByte(bytes[index])) {
      continuationCount += 1;
      index -= 1;
    }

    if (index < 0) {
      return const [];
    }

    final expectedLength = _expectedUtf8SequenceLength(bytes[index]);
    if (expectedLength <= 1) {
      return const [];
    }

    final availableLength = bytes.length - index;
    if (availableLength >= expectedLength) {
      return const [];
    }

    if (continuationCount != availableLength - 1) {
      return const [];
    }

    return bytes.sublist(index);
  }

  bool _isUtf8ContinuationByte(int byte) {
    return byte >= 0x80 && byte <= 0xBF;
  }

  int _expectedUtf8SequenceLength(int byte) {
    if (byte >= 0xC2 && byte <= 0xDF) {
      return 2;
    }
    if (byte >= 0xE0 && byte <= 0xEF) {
      return 3;
    }
    if (byte >= 0xF0 && byte <= 0xF4) {
      return 4;
    }
    return 1;
  }
}

/// Extension to make it easier to use Utf8StreamDecoder with streams.
extension Utf8StreamDecoderExtension on Stream<List<int>> {
  /// Transform a byte stream into a UTF-8 string stream with proper handling
  /// of incomplete multi-byte sequences.
  Stream<String> decodeUtf8Stream({
    bool allowMalformed = false,
  }) async* {
    yield* Utf8Decoder(allowMalformed: allowMalformed).bind(this);
  }
}

final class _Utf8DecodedChunkSink implements Sink<String> {
  final void Function(String chunk) _onChunk;

  const _Utf8DecodedChunkSink(this._onChunk);

  @override
  void add(String data) {
    if (data.isNotEmpty) {
      _onChunk(data);
    }
  }

  @override
  void close() {}
}
