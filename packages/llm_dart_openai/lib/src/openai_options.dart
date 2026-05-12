import 'package:llm_dart_provider/llm_dart_provider.dart';

export 'openai_image_types.dart';

import 'openai_image_types.dart';
import 'openai_native_tools.dart';
import 'openai_response_format.dart';

const Object _unset = Object();

final class OpenAIChatModelSettings implements ProviderModelOptions {
  final bool useResponsesApi;
  final String? organization;
  final String? project;
  final Map<String, String> headers;
  final List<OpenAIBuiltInTool> builtInTools;

  const OpenAIChatModelSettings({
    this.useResponsesApi = true,
    this.organization,
    this.project,
    this.headers = const {},
    this.builtInTools = const [],
  });
}

final class OpenAIEmbeddingModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIEmbeddingModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAISpeechModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAISpeechModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIImageModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIImageModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAITranscriptionModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAITranscriptionModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIEmbedOptions implements ProviderInvocationOptions {
  final String? encodingFormat;

  const OpenAIEmbedOptions({
    this.encodingFormat,
  });
}

final class OpenAIImageOptions implements ProviderInvocationOptions {
  final OpenAIImageStyle? style;
  final OpenAIImageQuality? quality;
  final OpenAIImageBackground? background;
  final OpenAIImageOutputFormat? outputFormat;
  final OpenAIImageResponseFormat? responseFormat;
  final String? user;

  const OpenAIImageOptions({
    this.style,
    this.quality,
    this.background,
    this.outputFormat,
    this.responseFormat,
    this.user,
  });
}

final class OpenAIPromptPartOptions implements ProviderPromptPartOptions {
  final String? imageDetail;

  const OpenAIPromptPartOptions({
    this.imageDetail,
  });
}

final class OpenAIPromptPartOptionsJsonCodec
    implements ProviderPromptPartOptionsJsonCodec<OpenAIPromptPartOptions> {
  static const typeId = 'openai.promptPartOptions';

  const OpenAIPromptPartOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderPromptPartOptions options) =>
      options is OpenAIPromptPartOptions;

  @override
  JsonMap encode(ProviderPromptPartOptions options) {
    final typed = options as OpenAIPromptPartOptions;
    return {
      if (typed.imageDetail != null) 'imageDetail': typed.imageDetail,
    };
  }

  @override
  OpenAIPromptPartOptions decode(JsonMap json) {
    return OpenAIPromptPartOptions(
      imageDetail: asNullableJsonString(
        json['imageDetail'],
        path: r'$.data.imageDetail',
      ),
    );
  }
}

const openAIPromptPartOptionsJsonCodec = OpenAIPromptPartOptionsJsonCodec();

final class OpenAISpeechOptions implements ProviderInvocationOptions {
  final String? outputFormat;
  final String? instructions;
  final double? speed;
  final String? language;

  const OpenAISpeechOptions({
    this.outputFormat,
    this.instructions,
    this.speed,
    this.language,
  });
}

enum OpenAITranscriptionResponseFormat {
  json('json'),
  text('text'),
  srt('srt'),
  verboseJson('verbose_json'),
  vtt('vtt');

  const OpenAITranscriptionResponseFormat(this.value);

  final String value;
}

enum OpenAITranscriptionTimestampGranularity {
  word('word'),
  segment('segment');

  const OpenAITranscriptionTimestampGranularity(this.value);

  final String value;
}

final class OpenAITranscriptionOptions implements ProviderInvocationOptions {
  final String? language;
  final String? prompt;
  final double? temperature;
  final OpenAITranscriptionResponseFormat? responseFormat;
  final List<OpenAITranscriptionTimestampGranularity> timestampGranularities;

  const OpenAITranscriptionOptions({
    this.language,
    this.prompt,
    this.temperature,
    this.responseFormat,
    this.timestampGranularities = const [],
  });
}

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
  reasoningEncryptedContent('reasoning.encrypted_content'),
  fileSearchCallResults('file_search_call.results'),
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
    Object? previousResponseId = _unset,
    Object? conversation = _unset,
    Object? store = _unset,
    Object? parallelToolCalls = _unset,
    Object? serviceTier = _unset,
    Object? verbosity = _unset,
    Object? instructions = _unset,
    Object? maxToolCalls = _unset,
    Object? metadata = _unset,
    Object? truncation = _unset,
    Object? user = _unset,
    Object? systemMessageMode = _unset,
    Object? reasoningEffort = _unset,
    Object? maxCompletionTokens = _unset,
    Object? forceReasoning = _unset,
    Object? logprobs = _unset,
    Object? include = _unset,
    Object? promptCacheKey = _unset,
    Object? promptCacheRetention = _unset,
    Object? safetyIdentifier = _unset,
    Object? builtInTools = _unset,
    Object? responseFormat = _unset,
  }) {
    return OpenAIGenerateTextOptions(
      previousResponseId: identical(previousResponseId, _unset)
          ? this.previousResponseId
          : previousResponseId as String?,
      conversation: identical(conversation, _unset)
          ? this.conversation
          : conversation as String?,
      store: identical(store, _unset) ? this.store : store as bool?,
      parallelToolCalls: identical(parallelToolCalls, _unset)
          ? this.parallelToolCalls
          : parallelToolCalls as bool?,
      serviceTier: identical(serviceTier, _unset)
          ? this.serviceTier
          : serviceTier as String?,
      verbosity:
          identical(verbosity, _unset) ? this.verbosity : verbosity as String?,
      instructions: identical(instructions, _unset)
          ? this.instructions
          : instructions as String?,
      maxToolCalls: identical(maxToolCalls, _unset)
          ? this.maxToolCalls
          : maxToolCalls as int?,
      metadata: identical(metadata, _unset)
          ? this.metadata
          : metadata as Map<String, Object?>?,
      truncation: identical(truncation, _unset)
          ? this.truncation
          : truncation as OpenAIResponseTruncation?,
      user: identical(user, _unset) ? this.user : user as String?,
      systemMessageMode: identical(systemMessageMode, _unset)
          ? this.systemMessageMode
          : systemMessageMode as OpenAISystemMessageMode?,
      reasoningEffort: identical(reasoningEffort, _unset)
          ? this.reasoningEffort
          : reasoningEffort as OpenAIReasoningEffort?,
      maxCompletionTokens: identical(maxCompletionTokens, _unset)
          ? this.maxCompletionTokens
          : maxCompletionTokens as int?,
      forceReasoning: identical(forceReasoning, _unset)
          ? this.forceReasoning
          : forceReasoning as bool?,
      logprobs: identical(logprobs, _unset)
          ? this.logprobs
          : logprobs as OpenAILogProbs?,
      include: identical(include, _unset)
          ? this.include
          : include as List<OpenAIResponsesInclude>?,
      promptCacheKey: identical(promptCacheKey, _unset)
          ? this.promptCacheKey
          : promptCacheKey as String?,
      promptCacheRetention: identical(promptCacheRetention, _unset)
          ? this.promptCacheRetention
          : promptCacheRetention as OpenAIPromptCacheRetention?,
      safetyIdentifier: identical(safetyIdentifier, _unset)
          ? this.safetyIdentifier
          : safetyIdentifier as String?,
      builtInTools: identical(builtInTools, _unset)
          ? this.builtInTools
          : builtInTools as List<OpenAIBuiltInTool>?,
      responseFormat: identical(responseFormat, _unset)
          ? this.responseFormat
          : responseFormat as OpenAIJsonSchemaResponseFormat?,
    );
  }
}
