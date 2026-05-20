import 'package:llm_dart_provider/llm_dart_provider.dart';

FinishReason mapOpenAIResponsesFinishReason({
  required String? rawReason,
  required bool hasToolCalls,
  required String? status,
}) {
  if (status == 'failed') {
    return FinishReason.error;
  }

  if (rawReason == null) {
    return hasToolCalls ? FinishReason.toolCalls : FinishReason.stop;
  }

  if (rawReason == 'max_output_tokens') {
    return FinishReason.maxTokens;
  }

  if (rawReason == 'content_filter') {
    return FinishReason.contentFilter;
  }

  if (rawReason == 'cancelled') {
    return FinishReason.aborted;
  }

  return hasToolCalls ? FinishReason.toolCalls : FinishReason.other;
}
