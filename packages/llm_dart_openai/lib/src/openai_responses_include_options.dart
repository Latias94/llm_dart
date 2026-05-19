import 'openai_generate_text_options.dart';
import 'openai_native_tools.dart';

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

  values.addAll(_providerNativeIncludes(providerOptions.builtInTools));

  if (!store && isReasoningModel) {
    values.add(OpenAIResponsesInclude.reasoningEncryptedContent.value);
  }

  if (values.isEmpty) {
    return null;
  }

  return values.toList(growable: false);
}

Iterable<String> _providerNativeIncludes(List<OpenAIBuiltInTool>? tools) sync* {
  if (tools == null) {
    return;
  }

  for (final tool in tools) {
    switch (tool) {
      case OpenAIWebSearchTool():
        yield OpenAIResponsesInclude.webSearchCallActionSources.value;
      case OpenAICodeInterpreterTool():
        yield OpenAIResponsesInclude.codeInterpreterCallOutputs.value;
      default:
        break;
    }
  }
}

int? _encodeOpenAIResponsesTopLogProbs(OpenAILogProbs? logprobs) {
  if (logprobs == null) {
    return null;
  }

  return logprobs.topLogProbs ?? OpenAILogProbs.responsesMaxTopLogProbs;
}
