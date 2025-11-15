import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/openai_compatible_config.dart';

/// Reasoning parameter helpers for OpenAI-compatible providers.
///
/// This mirrors the behavior of the historical reasoning-effort helpers,
/// but is scoped to OpenAI-compatible configs so that core utilities
/// remain provider-agnostic and free of provider-specific branching.
class OpenAICompatibleReasoningUtils {
  /// Build max tokens parameter for OpenAI-compatible chat APIs.
  ///
  /// - For OpenAI reasoning models (o1/o3/o4), this uses
  ///   `max_completion_tokens`.
  /// - For standard models, it uses `max_tokens`.
  static Map<String, dynamic> buildMaxTokensParams(
    OpenAICompatibleConfig config,
  ) {
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
  static bool shouldDisableTemperature(OpenAICompatibleConfig config) {
    return ReasoningUtils.isOpenAIReasoningModel(config.model);
  }

  /// Whether top_p should be disabled for this model.
  static bool shouldDisableTopP(OpenAICompatibleConfig config) {
    return ReasoningUtils.isOpenAIReasoningModel(config.model);
  }

  /// Build reasoning effort parameters according to provider/model.
  ///
  /// This supports:
  /// - Groq (no reasoning_effort)
  /// - OpenRouter (`reasoning.effort`)
  /// - Google Gemini (handled via request body transformer)
  /// - Grok (`reasoning_effort`)
  /// - Claude 3.7 / Sonnet 4 / Opus 4 (`thinking` with budget tokens)
  /// - Default (`reasoning_effort`)
  static Map<String, dynamic> buildReasoningEffortParams(
    OpenAICompatibleConfig config,
  ) {
    final reasoningEffort = config.reasoningEffort;
    if (reasoningEffort == null) return const {};

    final model = config.model;
    final providerId = config.providerId;

    // Groq doesn't support reasoning effort in this format.
    if (providerId == 'groq') {
      return const {};
    }

    // Google Gemini OpenAI-compatible reasoning effort is handled via
    // the provider-specific request body transformer.
    if (providerId == 'google-openai') {
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

    // Claude 3.7 Sonnet / Sonnet 4 / Opus 4 thinking support.
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

    // Default format (OpenAI-style reasoning_effort).
    return {
      'reasoning_effort': reasoningEffort.value,
    };
  }
}
