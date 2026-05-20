import 'openai_chat_completions_json_support.dart';

DateTime? openAIChatCompletionsDecodeResponseTimestamp(
  Map<String, Object?> response,
) {
  final created = openAIChatCompletionsAsInt(response['created']);
  if (created == null) {
    return null;
  }

  return DateTime.fromMillisecondsSinceEpoch(
    created * 1000,
    isUtc: true,
  );
}

Map<String, Object?>? openAIChatCompletionsFirstChoice(
  Map<String, Object?> response,
) {
  final choices = openAIChatCompletionsAsList(response['choices']);
  if (choices.isEmpty) {
    return null;
  }

  return openAIChatCompletionsAsMap(choices.first);
}

List<Object?>? openAIChatCompletionsDecodeLogprobs(Object? value) {
  final logprobs = openAIChatCompletionsAsMap(value);
  return openAIChatCompletionsJsonListOrNull(logprobs?['content']);
}
