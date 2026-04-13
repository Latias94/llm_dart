import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import 'client.dart';
import 'google_chat_response.dart';

/// Stateful streamed-event parser for the Google compatibility chat shell.
class GoogleChatStreamParser {
  final GoogleClient client;

  String _streamBuffer = '';
  bool _isFirstChunk = true;

  GoogleChatStreamParser({
    required this.client,
  });

  void reset() {
    _streamBuffer = '';
    _isFirstChunk = true;
  }

  List<ChatStreamEvent> parseChunk(String chunk) {
    final events = <ChatStreamEvent>[];

    try {
      _streamBuffer += chunk;

      if (_streamBuffer.contains('data:')) {
        while (true) {
          final sseSepCrlf = _streamBuffer.indexOf('\r\n\r\n');
          final sseSepLf = _streamBuffer.indexOf('\n\n');
          final hasCrlf = sseSepCrlf != -1;
          final hasLf = sseSepLf != -1;

          if (!hasCrlf && !hasLf) break;

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
          if (data.isEmpty || data == '[DONE]') continue;

          try {
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic>) {
              events.addAll(_parseStreamEvent(decoded));
            } else if (decoded is List) {
              for (final item in decoded) {
                if (item is Map<String, dynamic>) {
                  events.addAll(_parseStreamEvent(item));
                }
              }
            }
          } catch (e) {
            client.logger.warning('Failed to parse Google SSE data: $e');
            client.logger.fine('Raw SSE data: $data');
          }
        }

        return events;
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
          final json = jsonDecode(jsonAccumulator) as Map<String, dynamic>;
          events.addAll(_parseStreamEvent(json));
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

    return events;
  }

  List<ChatStreamEvent> _parseStreamEvent(Map<String, dynamic> json) {
    final out = <ChatStreamEvent>[];
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return out;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) return out;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      final finishReason = candidates.first['finishReason'] as String?;
      if (finishReason != null) {
        final usage = json['usageMetadata'] as Map<String, dynamic>?;
        out.add(
          CompletionEvent(
            GoogleChatResponse({
              'candidates': [],
              'usageMetadata': usage,
            }),
          ),
        );
      }
      return out;
    }

    for (final part in parts) {
      final isThought = part['thought'] as bool? ?? false;
      final text = part['text'] as String?;

      if (isThought && text != null && text.isNotEmpty) {
        out.add(ThinkingDeltaEvent(text));
        continue;
      }

      if (!isThought && text != null && text.isNotEmpty) {
        out.add(TextDeltaEvent(text));
        continue;
      }

      final inlineData = part['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final mimeType = inlineData['mimeType'] as String?;
        final data = inlineData['data'] as String?;
        if (mimeType != null && data != null && mimeType.startsWith('image/')) {
          out.add(TextDeltaEvent('[Generated image: $mimeType]'));
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

        out.add(ToolCallDeltaEvent(toolCall));
        continue;
      }
    }

    final finishReason = candidates.first['finishReason'] as String?;
    if (finishReason != null) {
      final usage = json['usageMetadata'] as Map<String, dynamic>?;
      out.add(
        CompletionEvent(
          GoogleChatResponse({
            'candidates': [],
            'usageMetadata': usage,
          }),
        ),
      );
    }

    return out;
  }
}
