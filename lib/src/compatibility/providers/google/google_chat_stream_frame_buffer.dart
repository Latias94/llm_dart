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

  List<Map<String, dynamic>> absorbChunk(String chunk) {
    final payloads = <Map<String, dynamic>>[];

    try {
      _streamBuffer += chunk;

      if (_streamBuffer.contains('data:')) {
        while (true) {
          final sseSepCrlf = _streamBuffer.indexOf('\r\n\r\n');
          final sseSepLf = _streamBuffer.indexOf('\n\n');
          final hasCrlf = sseSepCrlf != -1;
          final hasLf = sseSepLf != -1;

          if (!hasCrlf && !hasLf) {
            break;
          }

          final sepIndex = hasCrlf ? sseSepCrlf : sseSepLf;
          final sepLen = hasCrlf ? 4 : 2;

          final block = _streamBuffer.substring(0, sepIndex);
          _streamBuffer = _streamBuffer.substring(sepIndex + sepLen);

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
            final decoded = jsonDecode(data);
            payloads.addAll(_decodePayloads(decoded));
          } catch (e) {
            client.logger.warning('Failed to parse Google SSE data: $e');
            client.logger.fine('Raw SSE data: $data');
          }
        }

        return payloads;
      }

      var processedData = _streamBuffer.trim();

      if (_isFirstChunk && processedData.startsWith('[')) {
        processedData = processedData.replaceFirst('[', '');
        _isFirstChunk = false;
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
          final decoded = jsonDecode(jsonAccumulator);
          payloads.addAll(_decodePayloads(decoded));
          jsonAccumulator = '';
          _streamBuffer = '';
        } catch (_) {
          continue;
        }
      }

      if (jsonAccumulator.isNotEmpty) {
        _streamBuffer = jsonAccumulator;
      }
    } catch (e) {
      client.logger.warning('Failed to parse Google stream chunk: $e');
      client.logger.fine('Raw chunk: $chunk');
      client.logger.fine('Buffer content: $_streamBuffer');
    }

    return payloads;
  }

  List<Map<String, dynamic>> _decodePayloads(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      return [decoded];
    }

    if (decoded is Map) {
      return [Map<String, dynamic>.from(decoded)];
    }

    if (decoded is List) {
      final payloads = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          payloads.add(item);
        } else if (item is Map) {
          payloads.add(Map<String, dynamic>.from(item));
        }
      }
      return payloads;
    }

    return const [];
  }
}
