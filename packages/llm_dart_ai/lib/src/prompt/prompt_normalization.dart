import 'package:llm_dart_provider/llm_dart_provider.dart' show PromptMessage;

import 'model_message.dart';
import 'prompt_message_projection.dart';
import 'prompt_validation.dart';

List<PromptMessage> normalizeModelMessages(List<ModelMessage> messages) {
  final prompt = <PromptMessage>[];
  const projector = ModelMessagePromptProjector();

  for (final message in messages) {
    prompt.addAll(projector.project(message));
  }

  final normalized = List<PromptMessage>.unmodifiable(prompt);
  validateProviderPrompt(
    normalized,
    context: 'normalizeModelMessages.messages',
  );
  return normalized;
}

List<PromptMessage> resolveProviderPrompt({
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
}) {
  if (prompt != null && messages != null) {
    throw ArgumentError(
      'Provide either provider-facing prompt or user-facing messages, not both.',
    );
  }

  if (messages != null) {
    return normalizeModelMessages(messages);
  }

  if (prompt != null) {
    return List<PromptMessage>.unmodifiable(prompt);
  }

  throw ArgumentError(
    'Provide either provider-facing prompt or user-facing messages.',
  );
}
