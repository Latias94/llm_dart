import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_options.dart';

const List<String> googleNativeToolFamilies = [
  'google_search',
  'code_execution',
];

const List<String> googleThinkingLevels = [
  'minimal',
  'low',
  'medium',
  'high',
];

final class GoogleLanguageModelPolicy {
  final String modelId;

  const GoogleLanguageModelPolicy(this.modelId);

  String get _normalizedModelId => modelId.toLowerCase();

  bool get isGeminiModel => _normalizedModelId.contains('gemini');

  bool get isGemmaModel => _normalizedModelId.startsWith('gemma-');

  bool get isGemini3StyleModel => _normalizedModelId.contains('gemini-3');

  CapabilityConfidence get familyConfidence => isGeminiModel
      ? CapabilityConfidence.known
      : CapabilityConfidence.inferred;

  bool get supportsServerSideToolInvocations => isGemini3StyleModel;

  bool get supportsStructuredOutput => isGeminiModel;

  bool get supportsJsonResponseFormat => isGeminiModel;

  bool get supportsReasoningOutput => isGeminiModel;

  bool get supportsSourceOutput => isGeminiModel;

  bool get supportsFileOutput => isGeminiModel;

  bool get supportsNativeTools {
    return _normalizedModelId.contains('gemini-2') ||
        _normalizedModelId.contains('gemini-3') ||
        _normalizedModelId.endsWith('-latest') ||
        _normalizedModelId.contains('nano-banana');
  }

  bool get supportsFunctionCallIdReplay => isGemini3StyleModel;

  bool get shouldUseSystemInstruction => !isGemmaModel;

  bool supportsMixedToolRequests({
    required bool includeServerSideToolInvocations,
    required bool hasNativeTools,
    required bool hasFunctionTools,
  }) {
    return isGemini3StyleModel &&
        includeServerSideToolInvocations &&
        hasNativeTools &&
        hasFunctionTools;
  }

  Map<String, Object?>? encodeThinkingConfig({
    required GenerateTextOptions options,
    required GoogleGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final config = <String, Object?>{};
    final sharedReasoning = options.reasoning;

    if (providerOptions.includeThoughts != null) {
      config['includeThoughts'] = providerOptions.includeThoughts;
    } else if (sharedReasoning?.enabled == true) {
      config['includeThoughts'] = true;
    }

    if (isGemini3StyleModel) {
      _encodeGemini3ThinkingConfig(
        config: config,
        sharedReasoning: sharedReasoning,
        providerOptions: providerOptions,
        warnings: warnings,
      );
    } else {
      _encodeLegacyThinkingConfig(
        config: config,
        sharedReasoning: sharedReasoning,
        providerOptions: providerOptions,
        warnings: warnings,
      );
    }

    if (sharedReasoning?.enabled == false &&
        providerOptions.includeThoughts == null &&
        providerOptions.thinkingBudgetTokens == null &&
        providerOptions.thinkingLevel == null) {
      if (isGemini3StyleModel) {
        config['thinkingLevel'] = GoogleThinkingLevel.minimal.value;
      } else {
        config['thinkingBudget'] = 0;
      }
    }

    return config.isEmpty ? null : config;
  }

  void _encodeGemini3ThinkingConfig({
    required Map<String, Object?> config,
    required GenerateTextReasoningOptions? sharedReasoning,
    required GoogleGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final sharedThinkingLevel = _mapGoogleThinkingLevel(
      sharedReasoning?.effort,
    );
    if (providerOptions.thinkingLevel != null) {
      config['thinkingLevel'] = providerOptions.thinkingLevel!.value;
      if (sharedThinkingLevel != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'options.reasoning.effort',
            message:
                'Google providerOptions.thinkingLevel overrides shared options.reasoning.effort.',
          ),
        );
      }
    } else if (sharedThinkingLevel != null) {
      config['thinkingLevel'] = sharedThinkingLevel.value;
    }

    if (providerOptions.thinkingBudgetTokens != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'thinkingBudgetTokens',
          message:
              'thinkingBudgetTokens is ignored for Gemini 3 style Google models. Use thinkingLevel instead.',
        ),
      );
    }
    if (sharedReasoning?.budgetTokens != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning.budgetTokens',
          message:
              'options.reasoning.budgetTokens is ignored for Gemini 3 style Google models. Use reasoning.effort instead.',
        ),
      );
    }
  }

  void _encodeLegacyThinkingConfig({
    required Map<String, Object?> config,
    required GenerateTextReasoningOptions? sharedReasoning,
    required GoogleGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    if (providerOptions.thinkingBudgetTokens != null) {
      config['thinkingBudget'] = providerOptions.thinkingBudgetTokens;
      if (sharedReasoning?.budgetTokens != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'options.reasoning.budgetTokens',
            message:
                'Google providerOptions.thinkingBudgetTokens overrides shared options.reasoning.budgetTokens.',
          ),
        );
      }
    } else if (sharedReasoning?.budgetTokens != null) {
      config['thinkingBudget'] = sharedReasoning!.budgetTokens;
    }

    if (providerOptions.thinkingLevel != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'thinkingLevel',
          message:
              'thinkingLevel is only supported for Gemini 3 style Google models. Use thinkingBudgetTokens instead.',
        ),
      );
    }
    if (sharedReasoning?.effort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning.effort',
          message:
              'options.reasoning.effort is only mapped for Gemini 3 style Google models. Use reasoning.budgetTokens for other Google models.',
        ),
      );
    }
  }
}

GoogleThinkingLevel? _mapGoogleThinkingLevel(ReasoningEffort? effort) {
  return switch (effort) {
    null => null,
    ReasoningEffort.minimal => GoogleThinkingLevel.minimal,
    ReasoningEffort.low => GoogleThinkingLevel.low,
    ReasoningEffort.medium => GoogleThinkingLevel.medium,
    ReasoningEffort.high => GoogleThinkingLevel.high,
  };
}
