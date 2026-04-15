import 'package:llm_dart_core/ui.dart';

import 'chat_state.dart';

final class ChatSessionSnapshot {
  final String chatId;
  final List<PromptMessage> prompt;
  final List<ChatUiMessage> messages;
  final ChatStatus status;
  final ModelError? error;

  ChatSessionSnapshot({
    required this.chatId,
    required List<PromptMessage> prompt,
    required List<ChatUiMessage> messages,
    required this.status,
    this.error,
  })  : prompt = List.unmodifiable(prompt),
        messages = List.unmodifiable(messages);
}
