part of 'google_chat_stream_support.dart';

List<Object?> _absorbGoogleChatSseChunk(
  _GoogleChatStreamFrameBuffer buffer,
) {
  final payloads = <Object?>[];

  while (true) {
    final sseSepCrlf = buffer._streamBuffer.indexOf('\r\n\r\n');
    final sseSepLf = buffer._streamBuffer.indexOf('\n\n');
    final hasCrlf = sseSepCrlf != -1;
    final hasLf = sseSepLf != -1;

    if (!hasCrlf && !hasLf) {
      break;
    }

    final sepIndex = hasCrlf ? sseSepCrlf : sseSepLf;
    final sepLen = hasCrlf ? 4 : 2;

    final block = buffer._streamBuffer.substring(0, sepIndex);
    buffer._streamBuffer = buffer._streamBuffer.substring(sepIndex + sepLen);

    final dataLines = <String>[];
    for (final rawLine in const LineSplitter().convert(block)) {
      final line = rawLine.trimRight();
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    final data = dataLines.join('\n').trim();
    if (data.isEmpty || data == '[DONE]') {
      continue;
    }

    try {
      payloads.add(jsonDecode(data));
    } catch (e) {
      buffer.client.logger.warning('Failed to parse Google SSE data: $e');
      buffer.client.logger.fine('Raw SSE data: $data');
    }
  }

  return payloads;
}
