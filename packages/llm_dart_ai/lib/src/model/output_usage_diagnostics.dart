import 'package:llm_dart_provider/llm_dart_provider.dart';

Map<String, Object?> structuredOutputUsageToJson(UsageStats usage) {
  return {
    if (usage.inputTokens != null) 'inputTokens': usage.inputTokens,
    if (usage.outputTokens != null) 'outputTokens': usage.outputTokens,
    if (usage.totalTokens != null) 'totalTokens': usage.totalTokens,
    if (usage.reasoningTokens != null) 'reasoningTokens': usage.reasoningTokens,
  };
}
