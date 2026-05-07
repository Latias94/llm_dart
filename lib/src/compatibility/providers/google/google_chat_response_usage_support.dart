part of 'google_chat_response.dart';

final class _GoogleChatResponseUsageSupport {
  const _GoogleChatResponseUsageSupport();

  UsageInfo? extractUsage(Map<String, dynamic> rawResponse) {
    final usageMetadata = _asMap(rawResponse['usageMetadata']);
    if (usageMetadata == null) return null;

    return UsageInfo(
      promptTokens: _asInt(usageMetadata['promptTokenCount']),
      completionTokens: _asInt(usageMetadata['candidatesTokenCount']),
      totalTokens: _asInt(usageMetadata['totalTokenCount']),
      reasoningTokens: _asInt(usageMetadata['thoughtsTokenCount']),
    );
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
