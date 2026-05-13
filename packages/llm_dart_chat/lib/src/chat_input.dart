import 'package:llm_dart_ai/llm_dart_ai.dart';

final class ChatInput {
  final UserModelMessage message;

  const ChatInput.message(this.message);

  ChatInput.parts(
    List<ModelPart> parts, {
    ProviderPromptPartOptions? providerOptions,
  }) : message = UserModelMessage(
          parts: parts,
          providerOptions: providerOptions,
        );

  ChatInput.text(String text) : message = UserModelMessage.text(text);
}
