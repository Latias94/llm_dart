import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart' show Logger;

import '../../../../core/llm_error.dart';

/// Stateful SSE chunk parser used by OpenAI-family compatibility clients.
///
/// The parser owns boundary reconstruction for incomplete network chunks while
/// keeping the `OpenAIClient.parseSSEChunk(...)` public API stable.
class OpenAISseChunkParser {
  final Logger logger;
  final StringBuffer _buffer = StringBuffer();

  OpenAISseChunkParser(this.logger);

  List<Map<String, dynamic>> parse(String chunk) {
    final results = <Map<String, dynamic>>[];

    _buffer.write(chunk);
    final bufferContent = _buffer.toString();
    final lastNewlineIndex = bufferContent.lastIndexOf('\n');

    if (lastNewlineIndex == -1) {
      return results;
    }

    final completeContent = bufferContent.substring(0, lastNewlineIndex + 1);
    final remainingContent = bufferContent.substring(lastNewlineIndex + 1);

    _buffer.clear();
    if (remainingContent.isNotEmpty) {
      _buffer.write(remainingContent);
    }

    final lines = completeContent.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || !trimmedLine.startsWith('data: ')) {
        continue;
      }

      final data = trimmedLine.substring(6).trim();
      if (data == '[DONE]') {
        _buffer.clear();
        return [];
      }

      if (data.isEmpty) {
        continue;
      }

      try {
        final json = jsonDecode(data);
        if (json is! Map<String, dynamic>) {
          logger.warning('SSE chunk is not a JSON object: $data');
          continue;
        }

        final streamError = json['error'] as Map<String, dynamic>?;
        if (streamError != null) {
          final message = streamError['message'] as String? ?? 'Unknown error';
          final type = streamError['type'] as String?;
          final code = streamError['code']?.toString();

          throw ResponseFormatError(
            'SSE stream error: $message${type != null ? ' (type: $type)' : ''}${code != null ? ' (code: $code)' : ''}',
            data,
          );
        }

        results.add(json);
      } catch (error) {
        if (error is LLMError) {
          rethrow;
        }

        logger.warning('Failed to parse SSE chunk JSON: $error, data: $data');
      }
    }

    return results;
  }

  void reset() {
    _buffer.clear();
  }
}
