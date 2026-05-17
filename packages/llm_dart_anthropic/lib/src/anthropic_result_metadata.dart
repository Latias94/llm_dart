import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_result_util.dart';

FinishReason mapAnthropicResultFinishReason(String? rawReason) {
  switch (rawReason) {
    case 'pause_turn':
    case 'end_turn':
    case 'stop_sequence':
      return FinishReason.stop;
    case 'tool_use':
      return FinishReason.toolCalls;
    case 'max_tokens':
    case 'model_context_window_exceeded':
      return FinishReason.maxTokens;
    case 'refusal':
      return FinishReason.contentFilter;
    default:
      return FinishReason.other;
  }
}

UsageStats? decodeAnthropicResultUsage(Map<String, Object?>? usage) {
  if (usage == null) {
    return null;
  }

  final inputTokens = anthropicResultAsInt(usage['input_tokens']);
  final outputTokens = anthropicResultAsInt(usage['output_tokens']);
  return UsageStats(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalTokens: (inputTokens ?? 0) + (outputTokens ?? 0),
  );
}

Map<String, Object?>? decodeAnthropicResultContainer(
  Map<String, Object?>? container,
) {
  if (container == null) {
    return null;
  }

  return {
    if (anthropicResultAsString(container['id']) != null)
      'id': anthropicResultAsString(container['id']),
    if (anthropicResultAsString(container['expires_at']) != null)
      'expiresAt': anthropicResultAsString(container['expires_at']),
    if (container['skills'] != null)
      'skills': normalizeJsonValue(container['skills']),
  };
}
