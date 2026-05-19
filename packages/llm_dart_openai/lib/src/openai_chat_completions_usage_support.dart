import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_json_support.dart';

UsageStats? openAIChatCompletionsDecodeUsage(Map<String, Object?>? usage) {
  if (usage == null) {
    return null;
  }

  final inputTokens = openAIChatCompletionsAsInt(usage['prompt_tokens']);
  final outputTokens = openAIChatCompletionsAsInt(usage['completion_tokens']);
  final totalTokens = openAIChatCompletionsAsInt(usage['total_tokens']) ??
      ((inputTokens != null && outputTokens != null)
          ? inputTokens + outputTokens
          : null);
  final completionDetails =
      openAIChatCompletionsAsMap(usage['completion_tokens_details']);

  return UsageStats(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalTokens: totalTokens,
    reasoningTokens: openAIChatCompletionsAsInt(
      completionDetails?['reasoning_tokens'],
    ),
  );
}
