import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_logprobs.dart';
import '../tools/openai_native_tools.dart';
import 'openai_reasoning_options.dart';
import 'openai_response_format.dart';
import '../responses/openai_responses_text_options.dart';

export 'openai_logprobs.dart' show OpenAILogProbs;
export 'openai_reasoning_options.dart'
    show OpenAIReasoningEffort, mapSharedOpenAIReasoningEffort;
export '../responses/openai_responses_text_options.dart'
    show
        OpenAIPromptCacheRetention,
        OpenAIResponseTruncation,
        OpenAIResponsesInclude,
        OpenAISystemMessageMode;

const Object _unsetOpenAIGenerateTextOption = Object();

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
