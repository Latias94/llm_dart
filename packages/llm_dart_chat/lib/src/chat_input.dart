import 'package:llm_dart_core/foundation.dart';

final class ChatInput {
  final PromptMessage message;

  const ChatInput.message(this.message);

  ChatInput.text(String text) : message = UserPromptMessage.text(text);
}
