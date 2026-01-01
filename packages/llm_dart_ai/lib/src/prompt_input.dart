import 'package:llm_dart_core/llm_dart_core.dart';

sealed class StandardizedPromptInput {
  const StandardizedPromptInput();
}

class StandardizedChatMessages extends StandardizedPromptInput {
  final List<ChatMessage> messages;
  const StandardizedChatMessages(this.messages);
}

class StandardizedPromptIr extends StandardizedPromptInput {
  final Prompt prompt;
  const StandardizedPromptIr(this.prompt);
}

/// Vercel-style prompt standardization.
///
/// Rules:
/// - You must provide exactly one of: [prompt], [messages], [promptIr].
/// - [system] can be used with any of them.
/// - When [system] is provided, it is prepended as the first system message.
StandardizedPromptInput standardizePromptInput({
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
}) {
  final normalizedSystem = system?.trim();
  final hasSystem = normalizedSystem != null && normalizedSystem.isNotEmpty;

  final promptProvided = prompt != null;
  final messagesProvided = messages != null;
  final promptIrProvided = promptIr != null;

  final providedCount = (promptProvided ? 1 : 0) +
      (messagesProvided ? 1 : 0) +
      (promptIrProvided ? 1 : 0);

  if (providedCount != 1) {
    throw const InvalidRequestError(
      'Invalid prompt input: provide exactly one of `prompt`, `messages`, or `promptIr`.',
    );
  }

  if (promptProvided) {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      throw const InvalidRequestError('`prompt` must not be empty.');
    }

    return StandardizedChatMessages([
      if (hasSystem) ChatMessage.system(normalizedSystem),
      ChatMessage.user(normalizedPrompt),
    ]);
  }

  if (messagesProvided) {
    if (messages.isEmpty) {
      throw const InvalidRequestError('`messages` must not be empty.');
    }

    return StandardizedChatMessages([
      if (hasSystem) ChatMessage.system(normalizedSystem),
      ...messages,
    ]);
  }

  // promptIrProvided
  if (promptIr!.messages.isEmpty) {
    throw const InvalidRequestError('`promptIr.messages` must not be empty.');
  }

  if (!hasSystem) return StandardizedPromptIr(promptIr);

  return StandardizedPromptIr(
    Prompt(
      messages: [PromptMessage.system(normalizedSystem), ...promptIr.messages],
    ),
  );
}
