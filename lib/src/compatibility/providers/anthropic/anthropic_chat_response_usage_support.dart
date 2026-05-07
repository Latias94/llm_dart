part of 'anthropic_chat_response.dart';

final class _AnthropicChatResponseUsageSupport {
  const _AnthropicChatResponseUsageSupport();

  UsageInfo? extractUsage(Map<String, dynamic> rawResponse) {
    final usageData = _normalizeUsage(rawResponse['usage']);
    if (usageData == null) {
      return null;
    }

    final inputTokens = usageData['input_tokens'] as int? ?? 0;
    final outputTokens = usageData['output_tokens'] as int? ?? 0;

    return UsageInfo(
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: inputTokens + outputTokens,
      reasoningTokens: null,
    );
  }

  Map<String, dynamic>? _normalizeUsage(Object? rawUsage) {
    if (rawUsage == null) {
      return null;
    }
    if (rawUsage is Map<String, dynamic>) {
      return rawUsage;
    }
    if (rawUsage is Map) {
      return Map<String, dynamic>.from(rawUsage);
    }
    return null;
  }
}
