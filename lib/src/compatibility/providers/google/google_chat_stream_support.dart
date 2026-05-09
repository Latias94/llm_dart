import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import 'client.dart';
import 'google_chat_response.dart';

/// Stateful streaming support for Google chat parsing.
final class GoogleChatStreamSupport {
  final GoogleClient client;
  late final _GoogleChatStreamFrameBuffer _frameBuffer;
  late final _GoogleChatStreamPayloadDecoder _payloadDecoder;
  late final _GoogleChatStreamEventSupport _eventSupport;

  GoogleChatStreamSupport({
    required this.client,
  }) {
    _frameBuffer = _GoogleChatStreamFrameBuffer(client: client);
    _payloadDecoder = const _GoogleChatStreamPayloadDecoder();
    _eventSupport = const _GoogleChatStreamEventSupport();
  }

  void reset() {
    _frameBuffer.reset();
  }

  List<ChatStreamEvent> parseChunk(String chunk) {
    final events = <ChatStreamEvent>[];
    final payloads = _frameBuffer.absorbChunk(chunk);

    for (final payload in payloads) {
      final decodedPayloads = _payloadDecoder.decode(payload);
      for (final decodedPayload in decodedPayloads) {
        events.addAll(_eventSupport.mapPayload(decodedPayload));
      }
    }

    return events;
  }
}

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
        return _absorbSseChunk();
      }

      return _absorbJsonChunk();
    } catch (e) {
      client.logger.warning('Failed to parse Google stream chunk: $e');
      client.logger.fine('Raw chunk: $chunk');
      client.logger.fine('Buffer content: $_streamBuffer');
    }

    return const [];
  }

  List<Object?> _absorbJsonChunk() {
    final payloads = <Object?>[];
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
        payloads.add(jsonDecode(jsonAccumulator));
        jsonAccumulator = '';
        _streamBuffer = '';
      } catch (_) {
        continue;
      }
    }

    if (jsonAccumulator.isNotEmpty) {
      _streamBuffer = jsonAccumulator;
    }

    return payloads;
  }

  List<Object?> _absorbSseChunk() {
    final payloads = <Object?>[];

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
        payloads.add(jsonDecode(data));
      } catch (e) {
        client.logger.warning('Failed to parse Google SSE data: $e');
        client.logger.fine('Raw SSE data: $data');
      }
    }

    return payloads;
  }
}

final class _GoogleChatStreamPayloadDecoder {
  const _GoogleChatStreamPayloadDecoder();

  List<Map<String, dynamic>> decode(Object? decoded) {
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

final class _GoogleChatStreamEventSupport {
  const _GoogleChatStreamEventSupport();

  List<ChatStreamEvent> mapPayload(Map<String, dynamic> json) {
    final events = <ChatStreamEvent>[];
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return events;

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) return events;

    final content = firstCandidate['content'] as Map<String, dynamic>?;
    if (content == null) {
      return _appendCompletionIfPresent(events, json, firstCandidate);
    }

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      return _appendCompletionIfPresent(events, json, firstCandidate);
    }

    for (final part in parts) {
      if (part is! Map<String, dynamic>) {
        continue;
      }

      final isThought = part['thought'] as bool? ?? false;
      final text = part['text'] as String?;

      if (isThought && text != null && text.isNotEmpty) {
        events.add(ThinkingDeltaEvent(text));
        continue;
      }

      if (!isThought && text != null && text.isNotEmpty) {
        events.add(TextDeltaEvent(text));
        continue;
      }

      final inlineData = part['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final mimeType = inlineData['mimeType'] as String?;
        final data = inlineData['data'] as String?;
        if (mimeType != null && data != null && mimeType.startsWith('image/')) {
          events.add(TextDeltaEvent('[Generated image: $mimeType]'));
          continue;
        }
      }

      final functionCall = part['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final name = functionCall['name'] as String;
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        final toolCall = ToolCall(
          id: 'call_$name',
          callType: 'function',
          function: FunctionCall(name: name, arguments: jsonEncode(args)),
        );

        events.add(ToolCallDeltaEvent(toolCall));
      }
    }

    return _appendCompletionIfPresent(events, json, firstCandidate);
  }

  List<ChatStreamEvent> _appendCompletionIfPresent(
    List<ChatStreamEvent> events,
    Map<String, dynamic> json,
    Map<String, dynamic> candidate,
  ) {
    final finishReason = candidate['finishReason'] as String?;
    if (finishReason != null) {
      final usage = json['usageMetadata'] as Map<String, dynamic>?;
      events.add(
        CompletionEvent(
          GoogleChatResponse({
            'candidates': const [],
            'usageMetadata': usage,
          }),
        ),
      );
    }

    return events;
  }
}
