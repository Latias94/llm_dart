import '../../../models/chat_models.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

final class LegacyGoogleThinkingOptions {
  final bool reasoning;
  final bool? includeThoughts;
  final int? thinkingBudgetTokens;
  final String? reasoningEffortValue;

  const LegacyGoogleThinkingOptions({
    required this.reasoning,
    required this.includeThoughts,
    required this.thinkingBudgetTokens,
    required this.reasoningEffortValue,
  });

  ReasoningEffort? get reasoningEffort =>
      ReasoningEffort.fromString(reasoningEffortValue);

  bool get hasThinkingConfig =>
      reasoning || includeThoughts != null || thinkingBudgetTokens != null;

  bool get includeThoughtsHeader => reasoning || includeThoughts == true;

  Map<String, dynamic> toThinkingConfig() {
    final thinkingConfig = <String, dynamic>{};

    if (includeThoughts != null) {
      thinkingConfig['includeThoughts'] = includeThoughts;
    } else if (reasoning) {
      thinkingConfig['includeThoughts'] = true;
    }

    if (thinkingBudgetTokens != null) {
      thinkingConfig['thinkingBudget'] = thinkingBudgetTokens;
    }

    return thinkingConfig;
  }
}

LegacyGoogleThinkingOptions legacyGoogleThinkingOptions(
  LegacyProviderOptionView options,
) {
  return LegacyGoogleThinkingOptions(
    reasoning:
        options.getWithFlatFallback<bool>(LegacyExtensionKeys.reasoning) ??
            false,
    includeThoughts: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.includeThoughts,
    ),
    thinkingBudgetTokens: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.thinkingBudgetTokens,
    ),
    reasoningEffortValue: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.reasoningEffort,
    ),
  );
}
