import '../../../../models/chat_models.dart';

/// Owns reasoning-model request shaping for the OpenAI compatibility family.
final class OpenAICompatReasoningRequestSupport {
  const OpenAICompatReasoningRequestSupport._();

  /// Check if the model is an OpenAI reasoning model.
  ///
  /// This follows the same semantics as the TypeScript implementation:
  /// - Non-reasoning chat models like gpt-3.*, gpt-4.*, chatgpt-4o, gpt-5-chat*
  ///   are treated as standard models.
  /// - All other OpenAI models (o1/o3/o4 series, GPT-5 family, etc.) are
  ///   treated as reasoning models and use `max_completion_tokens` instead
  ///   of `max_tokens` and may have stricter parameter support.
  static bool isOpenAIReasoningModel(String model) {
    final id = model.toLowerCase();

    // Explicit non-reasoning chat families.
    if (id.startsWith('gpt-3')) return false;
    if (id.startsWith('gpt-4')) return false;
    if (id.startsWith('chatgpt-4o')) return false;
    if (id.startsWith('gpt-5-chat')) return false;

    // Everything else (o1/o3/o4, gpt-5, gpt-5.1, gpt-5-mini/nano/pro, etc.).
    return true;
  }

  /// Check if the model is known to support reasoning.
  ///
  /// This is a compatibility hint for OpenAI-family request shaping. Runtime
  /// response parsing should still rely on actual response content.
  static bool isKnownReasoningModel(String model) {
    final id = model.toLowerCase();

    final isOpenAIModel = id.startsWith('gpt-') ||
        id.startsWith('o1') ||
        id.startsWith('o3') ||
        id.startsWith('o4');

    final isOpenAIReasoning = isOpenAIModel && isOpenAIReasoningModel(model);

    return isOpenAIReasoning ||
        model == 'deepseek-reasoner' ||
        model == 'deepseek-r1' ||
        model.contains('claude-3.7-sonnet') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4') ||
        model.contains('qwen') && model.contains('reasoning') ||
        id.contains('reasoning') ||
        id.contains('thinking');
  }

  /// Get reasoning effort parameter for different OpenAI-compatible providers.
  static Map<String, dynamic> getReasoningEffortParams({
    required String providerId,
    required String model,
    ReasoningEffort? reasoningEffort,
    int? maxTokens,
  }) {
    if (reasoningEffort == null) return {};

    if (providerId == 'groq') {
      return {};
    }

    if (providerId == 'openrouter') {
      return {
        'reasoning': {
          'effort': reasoningEffort.value,
        },
      };
    }

    if (model.contains('grok') && isKnownReasoningModel(model)) {
      return {
        'reasoning_effort': reasoningEffort.value,
      };
    }

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
        return {};
      }

      final effectiveMaxTokens = maxTokens ?? 4096;
      final budgetTokens =
          (effectiveMaxTokens * effortRatio).clamp(1024, 32000).truncate();

      return {
        'thinking': {
          'type': 'enabled',
          'budget_tokens': budgetTokens,
        },
      };
    }

    return {
      'reasoning_effort': reasoningEffort.value,
    };
  }

  /// Get appropriate max tokens parameter for reasoning models.
  static Map<String, dynamic> getMaxTokensParams({
    required String model,
    int? maxTokens,
  }) {
    if (maxTokens == null) return {};

    if (isOpenAIReasoningModel(model)) {
      return {
        'max_completion_tokens': maxTokens,
      };
    }

    return {
      'max_tokens': maxTokens,
    };
  }

  /// Check if temperature should be disabled for reasoning models.
  static bool shouldDisableTemperature(String model) {
    if (isOpenAIReasoningModel(model)) {
      return true;
    }

    return false;
  }

  /// Check if top_p should be disabled for reasoning models.
  static bool shouldDisableTopP(String model) {
    if (isOpenAIReasoningModel(model)) {
      return true;
    }

    return false;
  }
}
