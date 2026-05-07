part of 'google_chat_stream_support.dart';

List<Object?> _absorbGoogleChatJsonChunk(
  _GoogleChatStreamFrameBuffer buffer,
) {
  final payloads = <Object?>[];
  var processedData = buffer._streamBuffer.trim();

  if (buffer._isFirstChunk && processedData.startsWith('[')) {
    processedData = processedData.replaceFirst('[', '');
    buffer._isFirstChunk = false;
  }

  if (processedData.startsWith(',')) {
    processedData = processedData.replaceFirst(',', '');
  }

  if (processedData.endsWith(']')) {
    processedData = processedData.substring(0, processedData.length - 1);
  }

  processedData = processedData.trim();

  final lines = const LineSplitter().convert(processedData);
  var jsonAccumulator = '';

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (jsonAccumulator == '' && trimmed == ',') {
      continue;
    }

    jsonAccumulator += trimmed;

    try {
      payloads.add(jsonDecode(jsonAccumulator));
      jsonAccumulator = '';
      buffer._streamBuffer = '';
    } catch (_) {
      continue;
    }
  }

  if (jsonAccumulator.isNotEmpty) {
    buffer._streamBuffer = jsonAccumulator;
  }

  return payloads;
}
