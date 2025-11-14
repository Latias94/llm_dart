class OllamaUtf8StreamDecoder {
  final StringBuffer _buffer = StringBuffer();

  String decode(List<int> chunk) {
    _buffer.write(String.fromCharCodes(chunk));
    final result = _buffer.toString();
    _buffer.clear();
    return result;
  }

  String flush() {
    final remaining = _buffer.toString();
    _buffer.clear();
    return remaining;
  }
}
