import 'dart:async';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import 'client.dart';

/// Runs the repeated OpenAI compatibility streaming facade loop while keeping
/// request shaping and incremental parsing in their dedicated modules.
Stream<ChatStreamEvent> runOpenAICompatibilityStream({
  required OpenAIClient client,
  required String endpoint,
  required Map<String, dynamic> requestBody,
  required void Function() resetParser,
  required List<ChatStreamEvent> Function(String chunk) parseChunk,
  TransportCancellation? cancelToken,
}) async* {
  resetParser();

  try {
    final stream = client.postStreamRaw(
      endpoint,
      requestBody,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      try {
        final events = parseChunk(chunk);
        for (final event in events) {
          yield event;
        }
      } catch (error) {
        client.logger.warning('Failed to parse stream chunk: $error');
      }
    }
  } catch (error) {
    if (error is LLMError) {
      rethrow;
    }

    throw GenericError('Stream error: $error');
  }
}
