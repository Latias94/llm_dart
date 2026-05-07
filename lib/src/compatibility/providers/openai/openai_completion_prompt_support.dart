part of 'openai_completion_support.dart';

final class _OpenAICompletionPromptSupport {
  const _OpenAICompletionPromptSupport();

  int estimateTokenCount(String text) {
    return (text.length / 4).ceil();
  }

  bool isPromptWithinLimits(String prompt, {int? maxTokens}) {
    final estimatedTokens = estimateTokenCount(prompt);
    final limit = maxTokens ?? 4096;
    return estimatedTokens <= limit;
  }

  String truncatePrompt(String prompt, {int? maxTokens}) {
    final limit = maxTokens ?? 4096;
    final estimatedTokens = estimateTokenCount(prompt);

    if (estimatedTokens <= limit) {
      return prompt;
    }

    final targetLength = (limit * 4 * 0.9).round();
    return prompt.substring(0, targetLength.clamp(0, prompt.length));
  }
}
