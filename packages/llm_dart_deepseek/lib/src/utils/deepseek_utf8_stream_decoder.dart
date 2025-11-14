/// UTF-8 stream decoder tailored for SSE streams.
///
/// This decoder handles the case where UTF-8 character sequences are split
/// across multiple byte chunks. It buffers incomplete sequences and only
/// emits valid UTF-8 strings.
class DeepSeekUtf8StreamDecoder {
  List<int> _buffer = [];

  /// Decode a new chunk of bytes into a UTF-8 string.
  String decode(List<int> chunk) {
    _buffer.addAll(chunk);

    int validLength = _buffer.length;
    while (validLength > 0) {
      try {
        final decoded = String.fromCharCodes(_buffer.sublist(0, validLength));
        _buffer = _buffer.sublist(validLength);
        return decoded;
      } catch (_) {
        validLength--;
      }
    }

    return '';
  }

  /// Flush any remaining buffered bytes.
  String flush() {
    if (_buffer.isEmpty) return '';
    final decoded = String.fromCharCodes(_buffer);
    _buffer = [];
    return decoded;
  }
}
