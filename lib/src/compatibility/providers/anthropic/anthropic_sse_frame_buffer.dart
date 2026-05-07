part of 'anthropic_chat_stream_support.dart';

/// A completed SSE line payload extracted from the Anthropic stream.
final class AnthropicSseFrame {
  final String? eventType;
  final String? data;

  const AnthropicSseFrame.event(this.eventType) : data = null;

  const AnthropicSseFrame.data(this.data) : eventType = null;
}

/// Buffers Anthropic SSE text chunks and returns only complete event/data lines.
final class AnthropicSseFrameBuffer {
  final StringBuffer _buffer = StringBuffer();

  void reset() {
    _buffer.clear();
  }

  List<AnthropicSseFrame> addChunk(String chunk) {
    final frames = <AnthropicSseFrame>[];

    _buffer.write(chunk);
    final bufferContent = _buffer.toString();
    final lastNewlineIndex = bufferContent.lastIndexOf('\n');

    if (lastNewlineIndex == -1) {
      return frames;
    }

    final completeContent = bufferContent.substring(0, lastNewlineIndex + 1);
    final remainingContent = bufferContent.substring(lastNewlineIndex + 1);

    _buffer.clear();
    if (remainingContent.isNotEmpty) {
      _buffer.write(remainingContent);
    }

    for (final line in completeContent.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        continue;
      }

      if (trimmedLine.startsWith('event: ')) {
        frames.add(AnthropicSseFrame.event(trimmedLine.substring(7).trim()));
        continue;
      }

      if (trimmedLine.startsWith('data: ')) {
        frames.add(AnthropicSseFrame.data(trimmedLine.substring(6).trim()));
      }
    }

    return frames;
  }
}
