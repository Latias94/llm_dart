import 'openai_chat_completions_json_support.dart';
import '../common/openai_streaming_support.dart';

String? openAIChatCompletionsExtractContentDelta(
  Map<String, Object?> delta,
) {
  return openAIChatCompletionsAsString(delta['content']);
}

String? openAIChatCompletionsExtractReasoningDelta(
  Map<String, Object?> delta,
) {
  return firstOpenAINonEmptyString([
    openAIChatCompletionsAsString(delta['reasoning_content']),
    openAIChatCompletionsAsString(delta['reasoning']),
    openAIChatCompletionsAsString(delta['thinking']),
  ]);
}
