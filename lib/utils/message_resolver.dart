import 'package:llm_dart_core/llm_dart_core.dart';

/// Resolve input into a list of [ChatMessage]s for text generation.
///
/// The preferred prompt-first representation is [promptMessages]
/// (a list of [ModelMessage]s). For backwards compatibility this
/// helper also accepts:
/// - [structuredPrompt] (single [ModelMessage])
/// - [messages] (legacy [ChatMessage] list)
/// - [prompt] (plain text)
List<ChatMessage> resolveMessagesForTextGeneration({
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
}) {
  if (promptMessages != null && promptMessages.isNotEmpty) {
    return promptMessages
        .map((prompt) => ChatMessage.fromPromptMessage(prompt))
        .toList();
  }

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
