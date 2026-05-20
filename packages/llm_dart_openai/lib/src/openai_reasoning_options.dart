import 'package:llm_dart_provider/llm_dart_provider.dart';

enum OpenAIReasoningEffort {
  none('none'),
  minimal('minimal'),
  low('low'),
  medium('medium'),
  high('high'),
  xhigh('xhigh');

  const OpenAIReasoningEffort(this.value);

  final String value;
}

OpenAIReasoningEffort? mapSharedOpenAIReasoningEffort(
  GenerateTextReasoningOptions? reasoning, {
  required List<ModelWarning> warnings,
}) {
  if (reasoning == null) {
    return null;
  }

  if (reasoning.budgetTokens != null) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'options.reasoning.budgetTokens',
        message:
            'OpenAI reasoning uses effort levels; budgetTokens is ignored.',
      ),
    );
  }

  if (reasoning.enabled == false) {
    return OpenAIReasoningEffort.none;
  }

  return switch (reasoning.effort) {
    null => null,
    ReasoningEffort.minimal => OpenAIReasoningEffort.minimal,
    ReasoningEffort.low => OpenAIReasoningEffort.low,
    ReasoningEffort.medium => OpenAIReasoningEffort.medium,
    ReasoningEffort.high => OpenAIReasoningEffort.high,
  };
}
