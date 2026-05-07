part of 'google_chat_stream_support.dart';

final class _GoogleChatStreamFrameBuffer {
  final GoogleClient client;

  String _streamBuffer = '';
  bool _isFirstChunk = true;

  _GoogleChatStreamFrameBuffer({
    required this.client,
  });

  void reset() {
    _streamBuffer = '';
    _isFirstChunk = true;
  }

  List<Object?> absorbChunk(String chunk) {
    try {
      _streamBuffer += chunk;

      if (_streamBuffer.contains('data:')) {
        return _absorbGoogleChatSseChunk(this);
      }

      return _absorbGoogleChatJsonChunk(this);
    } catch (e) {
      client.logger.warning('Failed to parse Google stream chunk: $e');
      client.logger.fine('Raw chunk: $chunk');
      client.logger.fine('Buffer content: $_streamBuffer');
    }

    return const [];
  }
}
