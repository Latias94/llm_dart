/// UTF-8 stream decoder tailored for Google JSON streaming.
class GoogleUtf8StreamDecoder {
  List<int> _buffer = [];

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

  String flush() {
    if (_buffer.isEmpty) return '';
    final decoded = String.fromCharCodes(_buffer);
    _buffer = [];
    return decoded;
  }
}
