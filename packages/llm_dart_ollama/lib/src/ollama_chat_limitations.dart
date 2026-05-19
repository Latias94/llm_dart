import 'package:llm_dart_provider/llm_dart_provider.dart';

UnsupportedError unsupportedOllamaPromptPart({
  required String role,
  required PromptPart part,
}) {
  return UnsupportedError(
    'Ollama $role prompt part ${part.runtimeType} is not supported yet.',
  );
}

UnsupportedError unsupportedOllamaUserFilePromptPart() {
  return UnsupportedError(
    'Ollama only supports image multimodal file prompt parts on the current modern chat path.',
  );
}

UnsupportedError missingOllamaPromptPartBytes({
  required String promptPartKind,
}) {
  return UnsupportedError(
    'Ollama $promptPartKind prompt parts require bytes, a data URI, or a configured OllamaBinaryResolver.',
  );
}

UnsupportedError unresolvedOllamaPromptPartUri({
  required String promptPartKind,
  required Uri uri,
}) {
  return UnsupportedError(
    'Ollama $promptPartKind prompt parts cannot encode URI $uri without bytes, a data URI, or a configured OllamaBinaryResolver.',
  );
}

const ollamaUserReasoningPromptWarning = ModelWarning(
  type: ModelWarningType.compatibility,
  field: 'prompt',
  message:
      'Ollama does not have a dedicated user reasoning-input field. The reasoning text has been appended to the user content.',
);

ModelWarning ollamaReasoningPromptReplayWarning(String messageRole) {
  return ModelWarning(
    type: ModelWarningType.compatibility,
    field: 'prompt',
    message:
        'Ollama does not support replaying $messageRole reasoning as a separate prompt field. The reasoning text has been appended to the message content.',
  );
}

const ollamaToolErrorReplayWarning = ModelWarning(
  type: ModelWarningType.compatibility,
  field: 'prompt',
  message:
      'Ollama does not support replaying tool error state separately. The tool result has been sent as a plain tool content message.',
);

const ollamaToolChoiceWarning = ModelWarning(
  type: ModelWarningType.compatibility,
  field: 'toolChoice',
  message:
      'Ollama does not support explicit toolChoice control. Declared tools remain available for provider-side automatic selection.',
);

const ollamaProviderReasoningOverrideWarning = ModelWarning(
  type: ModelWarningType.compatibility,
  field: 'options.reasoning',
  message:
      'Ollama providerOptions.reasoning overrides shared options.reasoning.',
);

const ollamaReasoningEffortWarning = ModelWarning(
  type: ModelWarningType.unsupported,
  field: 'options.reasoning.effort',
  message:
      'Ollama reasoning is a provider toggle; shared reasoning.effort is ignored.',
);

const ollamaReasoningBudgetTokensWarning = ModelWarning(
  type: ModelWarningType.unsupported,
  field: 'options.reasoning.budgetTokens',
  message:
      'Ollama reasoning is a provider toggle; shared reasoning.budgetTokens is ignored.',
);

const ollamaFrequencyPenaltyWarning = ModelWarning(
  type: ModelWarningType.unsupported,
  field: 'options.frequencyPenalty',
  message:
      'Ollama does not support shared frequencyPenalty; use provider-native sampling options when needed.',
);

const ollamaPresencePenaltyWarning = ModelWarning(
  type: ModelWarningType.unsupported,
  field: 'options.presencePenalty',
  message:
      'Ollama does not support shared presencePenalty; use provider-native sampling options when needed.',
);

const ollamaResponseFormatCompatibilityWarning = ModelWarning(
  type: ModelWarningType.compatibility,
  field: 'options.responseFormat',
  message:
      'Ollama only supports the shared JSON schema body. responseFormat name, description, and strict are ignored.',
);

void addOllamaWarningOnce(
  List<ModelWarning> warnings,
  ModelWarning warning,
) {
  if (warnings.contains(warning)) return;
  warnings.add(warning);
}
