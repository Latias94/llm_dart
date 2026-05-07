part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestGenerationThinkingSupport {
  final GoogleConfig config;

  const _GoogleChatRequestGenerationThinkingSupport(this.config);

  void applyThinkingConfig(
    Map<String, dynamic> generationConfig, {
    required bool stream,
  }) {
    if (config.reasoningEffort != null ||
        config.thinkingBudgetTokens != null ||
        config.includeThoughts != null) {
      final thinkingConfig = <String, dynamic>{};

      if (config.includeThoughts != null) {
        thinkingConfig['includeThoughts'] = config.includeThoughts;
      } else if (stream) {
        thinkingConfig['includeThoughts'] = true;
      }

      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['thinkingBudget'] = config.thinkingBudgetTokens;
      }

      if (thinkingConfig.isNotEmpty) {
        generationConfig['thinkingConfig'] = thinkingConfig;
      }
    } else if (stream) {
      generationConfig['thinkingConfig'] = {
        'includeThoughts': true,
      };
    }
  }
}
