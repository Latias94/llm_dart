import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_util.dart';

UsageStats? decodeOpenAIResponsesUsage(Map<String, Object?>? usage) {
  if (usage == null) {
    return null;
  }

  final inputTokens = openAIResponsesAsInt(usage['input_tokens']);
  final outputTokens = openAIResponsesAsInt(usage['output_tokens']);
  final totalTokens = openAIResponsesAsInt(usage['total_tokens']) ??
      ((inputTokens != null && outputTokens != null)
          ? inputTokens + outputTokens
          : null);
  final outputDetails = openAIResponsesAsMap(usage['output_tokens_details']);

  return UsageStats(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalTokens: totalTokens,
    reasoningTokens: openAIResponsesAsInt(
      outputDetails?['reasoning_tokens'],
    ),
  );
}
