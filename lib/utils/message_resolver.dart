import '../models/chat_models.dart';

/// Resolve input into a list of [ChatMessage]s for text generation.
///
/// Exactly one of [prompt], [messages], or [structuredPrompt] must be
/// provided; otherwise an [ArgumentError] is thrown.
List<ChatMessage> resolveMessagesForTextGeneration({
  String? prompt,
  List<ChatMessage>? messages,
  ChatPromptMessage? structuredPrompt,
}) {
  if (structuredPrompt != null) {
    return [ChatMessage.fromPromptMessage(structuredPrompt)];
  }

  if (messages != null && messages.isNotEmpty) {
    return messages;
  }

  if (prompt != null && prompt.isNotEmpty) {
    return [ChatMessage.user(prompt)];
  }

  throw ArgumentError(
    'You must provide either prompt, messages, or structuredPrompt for text generation.',
  );
}
