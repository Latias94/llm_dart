import '../../../models/chat_models.dart';

/// Encodes legacy `ChatMessage` values for OpenAI-compatible chat-completions
/// providers that still expose the 0.x provider classes directly.
List<Map<String, dynamic>> buildOpenAICompatibleLegacyMessages({
  required List<ChatMessage> messages,
  String? systemPrompt,
  bool includeName = true,
}) {
  final apiMessages = <Map<String, dynamic>>[];

  if (systemPrompt != null) {
    apiMessages.add({'role': 'system', 'content': systemPrompt});
  }

  for (final message in messages) {
    if (message.messageType case ToolResultMessage(:final results)) {
      for (final result in results) {
        apiMessages.add({
          'role': 'tool',
          'tool_call_id': result.id,
          'content': message.content.isNotEmpty
              ? message.content
              : (result.function.arguments.isNotEmpty
                  ? result.function.arguments
                  : 'Tool result'),
        });
      }
      continue;
    }

    apiMessages.add(
      encodeOpenAICompatibleLegacyMessage(
        message,
        includeName: includeName,
      ),
    );
  }

  return apiMessages;
}

Map<String, dynamic> encodeOpenAICompatibleLegacyMessage(
  ChatMessage message, {
  bool includeName = true,
}) {
  final result = <String, dynamic>{'role': message.role.name};

  if (includeName && message.name != null) {
    result['name'] = message.name;
  }

  switch (message.messageType) {
    case TextMessage():
      result['content'] = message.content;
    case ToolUseMessage(:final toolCalls):
      result['content'] = message.content;
      result['tool_calls'] = toolCalls.map((toolCall) {
        return toolCall.toJson();
      }).toList();
    case ToolResultMessage():
      throw StateError(
        'Tool result messages must be expanded with buildOpenAICompatibleLegacyMessages.',
      );
    default:
      result['content'] = message.content;
  }

  return result;
}
