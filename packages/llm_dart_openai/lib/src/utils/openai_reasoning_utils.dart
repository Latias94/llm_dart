import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/openai_config.dart';

/// OpenAI-specific reasoning parameter helpers.
///
/// This utility centralizes how we map unified configuration to the
/// OpenAI HTTP API parameters for reasoning models (o1/o3/o4) while
/// delegating generic reasoning detection to [ReasoningUtils].
class OpenAIReasoningUtils {
  /// Build max tokens parameter for OpenAI chat/Responses APIs.
  ///
  /// - For OpenAI reasoning models (o1/o3/o4), this uses the
  ///   `max_completion_tokens` field.
  /// - For standard models, it uses `max_tokens`.
  static Map<String, dynamic> buildMaxTokensParams(OpenAIConfig config) {
    final maxTokens = config.maxTokens;
    if (maxTokens == null) return const {};

    if (ReasoningUtils.isOpenAIReasoningModel(config.model)) {
      return {
        'max_completion_tokens': maxTokens,
      };
    }

    return {
      'max_tokens': maxTokens,
    };
  }

  /// Whether temperature should be disabled for this model.
  ///
  /// OpenAI reasoning models (o1/o3/o4) do not support temperature.
  static bool shouldDisableTemperature(OpenAIConfig config) {
    return ReasoningUtils.isOpenAIReasoningModel(config.model);
  }

  /// Whether top_p should be disabled for this model.
  ///
  /// OpenAI reasoning models (o1/o3/o4) do not support top_p.
  static bool shouldDisableTopP(OpenAIConfig config) {
    return ReasoningUtils.isOpenAIReasoningModel(config.model);
  }

  /// Build provider-specific reasoning effort parameters.
  ///
  /// This mirrors the historical reasoning-effort mapping behavior
  /// for OpenAI-style providers that are accessed via the OpenAI client,
  /// without relying on deprecated core helpers.
  static Map<String, dynamic> buildReasoningEffortParams({
    required String providerId,
    required OpenAIConfig config,
  }) {
    final reasoningEffort = config.reasoningEffort;
    if (reasoningEffort == null) return const {};

    final model = config.model;

    // Groq doesn't support reasoning effort in this format.
    if (providerId == 'groq') {
      return const {};
    }

    // OpenRouter format.
    if (providerId == 'openrouter') {
      return {
        'reasoning': {
          'effort': reasoningEffort.value,
        },
      };
    }

    // Grok reasoning models.
    if (model.contains('grok') && ReasoningUtils.isKnownReasoningModel(model)) {
      return {
        'reasoning_effort': reasoningEffort.value,
      };
    }

    // Claude 3.7 Sonnet thinking support (for OpenRouter-style routing).
    if (model.contains('claude-3.7-sonnet') ||
        model.contains('claude-sonnet-4') ||
        model.contains('claude-opus-4')) {
      const effortRatios = {
        ReasoningEffort.high: 0.8,
        ReasoningEffort.medium: 0.5,
        ReasoningEffort.low: 0.2,
      };

      final effortRatio = effortRatios[reasoningEffort];
      if (effortRatio == null) {
        return const {};
      }

      const defaultMaxTokens = 4096;
      final effectiveMaxTokens = config.maxTokens ?? defaultMaxTokens;
      final budgetTokens =
          (effectiveMaxTokens * effortRatio).clamp(1024, 32000).truncate();

      return {
        'thinking': {
          'type': 'enabled',
          'budget_tokens': budgetTokens,
        },
      };
    }

    // Default format (OpenAI and other compatible providers).
    return {
      'reasoning_effort': reasoningEffort.value,
    };
  }
}
