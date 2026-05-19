import 'package:llm_dart_provider/llm_dart_provider.dart';

FinishReason openAIChatCompletionsMapFinishReason(String? rawReason) {
  return switch (rawReason) {
    null || 'stop' => FinishReason.stop,
    'length' => FinishReason.maxTokens,
    'tool_calls' => FinishReason.toolCalls,
    'content_filter' => FinishReason.contentFilter,
    'cancelled' => FinishReason.aborted,
    _ => FinishReason.other,
  };
}
