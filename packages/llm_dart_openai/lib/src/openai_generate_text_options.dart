import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_native_tools.dart';
import 'openai_response_format.dart';

const Object _unsetOpenAIGenerateTextOption = Object();

enum OpenAIResponseTruncation {
  auto('auto'),
  disabled('disabled');

  const OpenAIResponseTruncation(this.value);

  final String value;
}

enum OpenAIPromptCacheRetention {
  inMemory('in_memory'),
  twentyFourHours('24h');

  const OpenAIPromptCacheRetention(this.value);

  final String value;
}

enum OpenAIResponsesInclude {
  webSearchCallActionSources('web_search_call.action.sources'),
  codeInterpreterCallOutputs('code_interpreter_call.outputs'),
  computerCallOutputImageUrl('computer_call_output.output.image_url'),
  reasoningEncryptedContent('reasoning.encrypted_content'),
  fileSearchCallResults('file_search_call.results'),
  messageInputImageImageUrl('message.input_image.image_url'),
  messageOutputTextLogprobs('message.output_text.logprobs');

  const OpenAIResponsesInclude(this.value);

  final String value;
}

enum OpenAISystemMessageMode {
  system('system'),
  developer('developer'),
  remove('remove');

  const OpenAISystemMessageMode(this.value);

  final String value;
}

enum OpenAIReasoningEffort {
  none('none'),
  minimal('minimal'),
  low('low'),
  medium('medium'),
  high('high'),
  xhigh('xhigh');

  const OpenAIReasoningEffort(this.value);

  final String value;
}

OpenAIReasoningEffort? mapSharedOpenAIReasoningEffort(
  GenerateTextReasoningOptions? reasoning, {
  required List<ModelWarning> warnings,
}) {
  if (reasoning == null) {
    return null;
  }

  if (reasoning.budgetTokens != null) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'options.reasoning.budgetTokens',
        message:
            'OpenAI reasoning uses effort levels; budgetTokens is ignored.',
      ),
    );
  }

  if (reasoning.enabled == false) {
    return OpenAIReasoningEffort.none;
  }

  return switch (reasoning.effort) {
    null => null,
    ReasoningEffort.minimal => OpenAIReasoningEffort.minimal,
    ReasoningEffort.low => OpenAIReasoningEffort.low,
    ReasoningEffort.medium => OpenAIReasoningEffort.medium,
    ReasoningEffort.high => OpenAIReasoningEffort.high,
  };
}

final class OpenAILogProbs {
  static const int responsesMaxTopLogProbs = 20;

  final int? topLogProbs;

  const OpenAILogProbs.enabled() : topLogProbs = null;

  const OpenAILogProbs.top(this.topLogProbs)
      : assert(topLogProbs != null ? topLogProbs > 0 : false),
        assert(
          topLogProbs != null ? topLogProbs <= responsesMaxTopLogProbs : false,
        );
}

final class OpenAIGenerateTextOptions implements ProviderInvocationOptions {
  final String? previousResponseId;
  final String? conversation;
  final bool? store;
  final bool? parallelToolCalls;
  final String? serviceTier;
  final String? verbosity;
  final String? instructions;
  final int? maxToolCalls;
  final Map<String, Object?>? metadata;
  final OpenAIResponseTruncation? truncation;
  final String? user;
  final OpenAISystemMessageMode? systemMessageMode;
  final OpenAIReasoningEffort? reasoningEffort;
  final int? maxCompletionTokens;
  final bool? forceReasoning;
  final OpenAILogProbs? logprobs;
  final List<OpenAIResponsesInclude>? include;
  final String? promptCacheKey;
  final OpenAIPromptCacheRetention? promptCacheRetention;
  final String? safetyIdentifier;
  final List<OpenAIBuiltInTool>? builtInTools;
  final OpenAIJsonSchemaResponseFormat? responseFormat;

  const OpenAIGenerateTextOptions({
    this.previousResponseId,
    this.conversation,
    this.store,
    this.parallelToolCalls,
    this.serviceTier,
    this.verbosity,
    this.instructions,
    this.maxToolCalls,
    this.metadata,
    this.truncation,
    this.user,
    this.systemMessageMode,
    this.reasoningEffort,
    this.maxCompletionTokens,
    this.forceReasoning,
    this.logprobs,
    this.include,
    this.promptCacheKey,
    this.promptCacheRetention,
    this.safetyIdentifier,
    this.builtInTools,
    this.responseFormat,
  });

  OpenAIGenerateTextOptions copyWith({
    Object? previousResponseId = _unsetOpenAIGenerateTextOption,
    Object? conversation = _unsetOpenAIGenerateTextOption,
    Object? store = _unsetOpenAIGenerateTextOption,
    Object? parallelToolCalls = _unsetOpenAIGenerateTextOption,
    Object? serviceTier = _unsetOpenAIGenerateTextOption,
    Object? verbosity = _unsetOpenAIGenerateTextOption,
    Object? instructions = _unsetOpenAIGenerateTextOption,
    Object? maxToolCalls = _unsetOpenAIGenerateTextOption,
    Object? metadata = _unsetOpenAIGenerateTextOption,
    Object? truncation = _unsetOpenAIGenerateTextOption,
    Object? user = _unsetOpenAIGenerateTextOption,
    Object? systemMessageMode = _unsetOpenAIGenerateTextOption,
    Object? reasoningEffort = _unsetOpenAIGenerateTextOption,
    Object? maxCompletionTokens = _unsetOpenAIGenerateTextOption,
    Object? forceReasoning = _unsetOpenAIGenerateTextOption,
    Object? logprobs = _unsetOpenAIGenerateTextOption,
    Object? include = _unsetOpenAIGenerateTextOption,
    Object? promptCacheKey = _unsetOpenAIGenerateTextOption,
    Object? promptCacheRetention = _unsetOpenAIGenerateTextOption,
    Object? safetyIdentifier = _unsetOpenAIGenerateTextOption,
    Object? builtInTools = _unsetOpenAIGenerateTextOption,
    Object? responseFormat = _unsetOpenAIGenerateTextOption,
  }) {
    return OpenAIGenerateTextOptions(
      previousResponseId:
          identical(previousResponseId, _unsetOpenAIGenerateTextOption)
              ? this.previousResponseId
              : previousResponseId as String?,
      conversation: identical(conversation, _unsetOpenAIGenerateTextOption)
          ? this.conversation
          : conversation as String?,
      store: identical(store, _unsetOpenAIGenerateTextOption)
          ? this.store
          : store as bool?,
      parallelToolCalls:
          identical(parallelToolCalls, _unsetOpenAIGenerateTextOption)
              ? this.parallelToolCalls
              : parallelToolCalls as bool?,
      serviceTier: identical(serviceTier, _unsetOpenAIGenerateTextOption)
          ? this.serviceTier
          : serviceTier as String?,
      verbosity: identical(verbosity, _unsetOpenAIGenerateTextOption)
          ? this.verbosity
          : verbosity as String?,
      instructions: identical(instructions, _unsetOpenAIGenerateTextOption)
          ? this.instructions
          : instructions as String?,
      maxToolCalls: identical(maxToolCalls, _unsetOpenAIGenerateTextOption)
          ? this.maxToolCalls
          : maxToolCalls as int?,
      metadata: identical(metadata, _unsetOpenAIGenerateTextOption)
          ? this.metadata
          : metadata as Map<String, Object?>?,
      truncation: identical(truncation, _unsetOpenAIGenerateTextOption)
          ? this.truncation
          : truncation as OpenAIResponseTruncation?,
      user: identical(user, _unsetOpenAIGenerateTextOption)
          ? this.user
          : user as String?,
      systemMessageMode:
          identical(systemMessageMode, _unsetOpenAIGenerateTextOption)
              ? this.systemMessageMode
              : systemMessageMode as OpenAISystemMessageMode?,
      reasoningEffort:
          identical(reasoningEffort, _unsetOpenAIGenerateTextOption)
              ? this.reasoningEffort
              : reasoningEffort as OpenAIReasoningEffort?,
      maxCompletionTokens:
          identical(maxCompletionTokens, _unsetOpenAIGenerateTextOption)
              ? this.maxCompletionTokens
              : maxCompletionTokens as int?,
      forceReasoning: identical(forceReasoning, _unsetOpenAIGenerateTextOption)
          ? this.forceReasoning
          : forceReasoning as bool?,
      logprobs: identical(logprobs, _unsetOpenAIGenerateTextOption)
          ? this.logprobs
          : logprobs as OpenAILogProbs?,
      include: identical(include, _unsetOpenAIGenerateTextOption)
          ? this.include
          : include as List<OpenAIResponsesInclude>?,
      promptCacheKey: identical(promptCacheKey, _unsetOpenAIGenerateTextOption)
          ? this.promptCacheKey
          : promptCacheKey as String?,
      promptCacheRetention:
          identical(promptCacheRetention, _unsetOpenAIGenerateTextOption)
              ? this.promptCacheRetention
              : promptCacheRetention as OpenAIPromptCacheRetention?,
      safetyIdentifier:
          identical(safetyIdentifier, _unsetOpenAIGenerateTextOption)
              ? this.safetyIdentifier
              : safetyIdentifier as String?,
      builtInTools: identical(builtInTools, _unsetOpenAIGenerateTextOption)
          ? this.builtInTools
          : builtInTools as List<OpenAIBuiltInTool>?,
      responseFormat: identical(responseFormat, _unsetOpenAIGenerateTextOption)
          ? this.responseFormat
          : responseFormat as OpenAIJsonSchemaResponseFormat?,
    );
  }
}
