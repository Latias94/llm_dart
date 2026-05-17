import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_options.dart';

const int anthropicDefaultMaxTokens = 1024;
const int anthropicDefaultThinkingBudgetTokens = 1024;

final class AnthropicThinkingSamplingProjection {
  final bool extendedThinking;
  final int maxTokens;
  final double? temperature;
  final double? topP;
  final int? topK;
  final Map<String, Object?>? thinking;

  const AnthropicThinkingSamplingProjection({
    required this.extendedThinking,
    required this.maxTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.thinking,
  });
}

final class AnthropicThinkingPolicy {
  const AnthropicThinkingPolicy();

  AnthropicThinkingSamplingProjection project({
    required GenerateTextOptions options,
    required AnthropicGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final sharedReasoning = options.reasoning;
    final sharedRequestsThinking = sharedReasoning != null &&
        sharedReasoning.enabled != false &&
        (sharedReasoning.enabled == true ||
            sharedReasoning.budgetTokens != null ||
            sharedReasoning.effort != null);
    final extendedThinking =
        providerOptions.extendedThinking ?? sharedRequestsThinking;
    var maxTokens = options.maxOutputTokens ?? anthropicDefaultMaxTokens;
    final temperature = _normalizeTemperature(
      options.temperature,
      warnings: warnings,
    );
    double? topP = options.topP;
    int? topK = options.topK;
    Map<String, Object?>? thinking;

    if (sharedReasoning?.effort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.reasoning.effort',
          message:
              'Anthropic extended thinking uses a token budget; shared reasoning.effort is ignored.',
        ),
      );
    }

    if (sharedReasoning?.enabled == false &&
        (sharedReasoning?.budgetTokens != null ||
            sharedReasoning?.effort != null)) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning',
          message:
              'options.reasoning.enabled=false disables shared Anthropic thinking; budgetTokens and effort are ignored.',
        ),
      );
    }

    if (providerOptions.thinkingBudgetTokens != null && !extendedThinking) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'thinkingBudgetTokens',
          message:
              'thinkingBudgetTokens is ignored when extendedThinking is not enabled.',
        ),
      );
    }

    if (extendedThinking) {
      var thinkingBudget = providerOptions.thinkingBudgetTokens ??
          sharedReasoning?.budgetTokens ??
          anthropicDefaultThinkingBudgetTokens;
      if (providerOptions.thinkingBudgetTokens != null &&
          sharedReasoning?.budgetTokens != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'options.reasoning.budgetTokens',
            message:
                'Anthropic providerOptions.thinkingBudgetTokens overrides shared options.reasoning.budgetTokens.',
          ),
        );
      } else if (providerOptions.thinkingBudgetTokens == null &&
          sharedReasoning?.budgetTokens == null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message:
                'thinkingBudgetTokens is required when extendedThinking is enabled. Using the default budget of 1024 tokens.',
          ),
        );
      } else if (thinkingBudget < anthropicDefaultThinkingBudgetTokens) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message:
                'Anthropic extended thinking requires a minimum budget of 1024 tokens. The budget has been raised to 1024.',
          ),
        );
        thinkingBudget = anthropicDefaultThinkingBudgetTokens;
      }

      if (temperature != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'temperature',
            message: 'temperature is not supported when thinking is enabled.',
          ),
        );
      }

      if (topP != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topP',
            message: 'topP is not supported when thinking is enabled.',
          ),
        );
        topP = null;
      }

      if (topK != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topK',
            message: 'topK is not supported when thinking is enabled.',
          ),
        );
        topK = null;
      }

      maxTokens += thinkingBudget;
      thinking = {
        'type': 'enabled',
        'budget_tokens': thinkingBudget,
      };
    } else if (temperature != null && topP != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'topP',
          message: 'topP is ignored when temperature is set for Anthropic.',
        ),
      );
      topP = null;
    }

    return AnthropicThinkingSamplingProjection(
      extendedThinking: extendedThinking,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
      thinking: thinking,
    );
  }

  double? _normalizeTemperature(
    double? value, {
    required List<ModelWarning> warnings,
  }) {
    if (value == null) {
      return null;
    }

    if (value > 1) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'temperature',
          message:
              '$value exceeds Anthropic maximum temperature of 1.0. It has been clamped to 1.0.',
        ),
      );
      return 1;
    }

    if (value < 0) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'temperature',
          message:
              '$value is below Anthropic minimum temperature of 0. It has been clamped to 0.',
        ),
      );
      return 0;
    }

    return value;
  }
}
