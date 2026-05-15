import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_stream_util.dart';
import 'openai_chat_completions_support.dart';

GenerateTextResult decodeOpenAIChatCompletionsGenerateResponse(
  Map<String, Object?> response, {
  required OpenAIChatCompletionsSupport support,
  List<ModelWarning> warnings = const [],
}) {
  _throwIfOpenAIChatCompletionsError(response);

  final choice = openAIChatCompletionsFirstChoice(response);
  final message = openAIChatCompletionsAsMap(choice?['message']) ??
      const <String, Object?>{};
  final content = <ContentPart>[];
  final textLogprobs = openAIChatCompletionsDecodeLogprobs(choice?['logprobs']);
  final rawFinishReason =
      openAIChatCompletionsAsString(choice?['finish_reason']);

  final decodedText = support.decodeAssistantText(message);
  if (decodedText.reasoning case final reasoning? when reasoning.isNotEmpty) {
    content.add(
      ReasoningContentPart(
        reasoning,
        providerMetadata: support.providerMetadata({
          'finishReason': rawFinishReason,
        }),
      ),
    );
  }

  if (decodedText.text.isNotEmpty) {
    content.add(
      TextContentPart(
        decodedText.text,
        providerMetadata: support.providerMetadata({
          'finishReason': rawFinishReason,
          'logprobs': textLogprobs,
        }),
      ),
    );
  }

  final toolCalls = support.decodeToolCalls(
    openAIChatCompletionsAsList(message['tool_calls']),
  );
  content.addAll(toolCalls);
  content.addAll(support.decodeTopLevelSources(response));

  return GenerateTextResult(
    content: content,
    finishReason: openAIChatCompletionsMapFinishReason(rawFinishReason),
    rawFinishReason: rawFinishReason,
    responseId: openAIChatCompletionsAsString(response['id']),
    responseTimestamp: openAIChatCompletionsDecodeResponseTimestamp(response),
    responseModelId: openAIChatCompletionsAsString(response['model']),
    usage: openAIChatCompletionsDecodeUsage(
      openAIChatCompletionsAsMap(response['usage']),
    ),
    providerMetadata: support.responseMetadata(
      response,
      choice,
      logprobs: textLogprobs,
    ),
    warnings: warnings,
  );
}

void _throwIfOpenAIChatCompletionsError(Map<String, Object?> response) {
  final error = openAIChatCompletionsAsMap(response['error']);
  if (error == null) {
    return;
  }

  final message = openAIChatCompletionsAsString(error['message']) ??
      'OpenAI response error';
  final type = openAIChatCompletionsAsString(error['type']);
  final code = error['code'];
  throw StateError(
    'OpenAI chat-completions error: $message'
    '${type == null ? '' : ' (type: $type)'}'
    '${code == null ? '' : ' (code: $code)'}',
  );
}
