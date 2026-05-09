import '../../../../models/chat_models.dart';
import 'client.dart';
import 'config_views.dart';

/// Builds OpenAI-compatible request messages while preserving the legacy
/// compatibility rule that config-level system prompts are only prepended when
/// the caller did not already provide an explicit system message.
List<Map<String, dynamic>> buildOpenAICompatApiMessages({
  required OpenAIClient client,
  required OpenAIRequestCompatibilityConfigView requestConfig,
  required List<ChatMessage> messages,
}) {
  final apiMessages = client.buildApiMessages(messages);
  final hasSystemMessage =
      messages.any((message) => message.role == ChatRole.system);

  if (!hasSystemMessage && requestConfig.systemPrompt != null) {
    apiMessages.insert(0, {
      'role': 'system',
      'content': requestConfig.systemPrompt,
    });
  }

  return apiMessages;
}
