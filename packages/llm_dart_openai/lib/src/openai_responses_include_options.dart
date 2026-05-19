import 'openai_generate_text_options.dart';

final class OpenAIResponsesResolvedIncludeOptions {
  final List<String>? include;
  final int? topLogProbs;

  const OpenAIResponsesResolvedIncludeOptions({
    required this.include,
    required this.topLogProbs,
  });
}

OpenAIResponsesResolvedIncludeOptions resolveOpenAIResponsesIncludeOptions(
  OpenAIGenerateTextOptions providerOptions, {
  required bool isReasoningModel,
  required bool store,
}) {
  final include = _resolveOpenAIResponsesInclude(
    providerOptions,
    isReasoningModel: isReasoningModel,
    store: store,
  );
  final topLogProbs = _encodeOpenAIResponsesTopLogProbs(
    providerOptions.logprobs,
  );

  return OpenAIResponsesResolvedIncludeOptions(
    include: include,
    topLogProbs: topLogProbs,
  );
}

List<String>? _resolveOpenAIResponsesInclude(
  OpenAIGenerateTextOptions providerOptions, {
  required bool isReasoningModel,
  required bool store,
}) {
  final values = <String>{};

  if (providerOptions.include case final include?) {
    for (final item in include) {
      values.add(item.value);
    }
  }

  if (providerOptions.logprobs != null) {
    values.add(OpenAIResponsesInclude.messageOutputTextLogprobs.value);
  }

  if (!store && isReasoningModel) {
    values.add(OpenAIResponsesInclude.reasoningEncryptedContent.value);
  }

  if (values.isEmpty) {
    return null;
  }

  return values.toList(growable: false);
}

int? _encodeOpenAIResponsesTopLogProbs(OpenAILogProbs? logprobs) {
  if (logprobs == null) {
    return null;
  }

  return logprobs.topLogProbs ?? OpenAILogProbs.responsesMaxTopLogProbs;
}
