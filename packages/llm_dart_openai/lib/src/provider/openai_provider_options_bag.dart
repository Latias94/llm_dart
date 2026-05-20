import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../embedding/openai_embedding_options.dart';
import '../image/openai_image_options.dart';
import '../image/openai_image_types.dart';
import '../language/openai_generate_text_options.dart';
import '../language/openai_response_format.dart';
import '../speech/openai_speech_options.dart';
import '../transcription/openai_transcription_options.dart';
import 'deepseek_options.dart';
import 'openrouter_options.dart';
import 'xai_options.dart';

const openAIProviderOptionsNamespace = 'openai';
const deepSeekProviderOptionsNamespace = 'deepseek';
const openRouterProviderOptionsNamespace = 'openrouter';
const xaiProviderOptionsNamespace = 'xai';

OpenAIGenerateTextOptions resolveOpenAIGenerateTextOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typed = resolveProviderInvocationOptions<OpenAIGenerateTextOptions>(
    options,
    parameterName: 'providerOptions',
    expectedTypeName: 'OpenAIGenerateTextOptions',
  );
  final bagOptions = parseOpenAIGenerateTextOptionsBag(
    providerOptionsBagFromInvocationOptions(options),
    namespace: openAIProviderOptionsNamespace,
  );

  return mergeOpenAIGenerateTextOptions(
    base: bagOptions,
    override: typed,
  );
}

OpenAIGenerateTextOptions parseOpenAIGenerateTextOptionsBag(
  ProviderOptionsBag? bag, {
  String namespace = openAIProviderOptionsNamespace,
}) {
  final values = bag?.namespace(namespace);
  if (values == null || values.isEmpty) {
    return const OpenAIGenerateTextOptions();
  }

  return OpenAIGenerateTextOptions(
    previousResponseId: _optionalString(
      values,
      'previousResponseId',
      snakeKey: 'previous_response_id',
      path: _path(namespace, 'previousResponseId'),
    ),
    conversation: _optionalString(
      values,
      'conversation',
      path: _path(namespace, 'conversation'),
    ),
    store: _optionalBool(values, 'store', path: _path(namespace, 'store')),
    parallelToolCalls: _optionalBool(
      values,
      'parallelToolCalls',
      snakeKey: 'parallel_tool_calls',
      path: _path(namespace, 'parallelToolCalls'),
    ),
    serviceTier: _optionalString(
      values,
      'serviceTier',
      snakeKey: 'service_tier',
      path: _path(namespace, 'serviceTier'),
    ),
    verbosity: _optionalString(
      values,
      'verbosity',
      path: _path(namespace, 'verbosity'),
    ),
    instructions: _optionalString(
      values,
      'instructions',
      path: _path(namespace, 'instructions'),
    ),
    maxToolCalls: _optionalInt(
      values,
      'maxToolCalls',
      snakeKey: 'max_tool_calls',
      path: _path(namespace, 'maxToolCalls'),
    ),
    metadata: _optionalMap(
      values,
      'metadata',
      path: _path(namespace, 'metadata'),
    ),
    truncation: _optionalEnumByWireValue(
      values,
      'truncation',
      OpenAIResponseTruncation.values,
      (value) => value.value,
      path: _path(namespace, 'truncation'),
    ),
    user: _optionalString(values, 'user', path: _path(namespace, 'user')),
    systemMessageMode: _optionalEnumByWireValue(
      values,
      'systemMessageMode',
      OpenAISystemMessageMode.values,
      (value) => value.value,
      snakeKey: 'system_message_mode',
      path: _path(namespace, 'systemMessageMode'),
    ),
    reasoningEffort: _optionalEnumByWireValue(
      values,
      'reasoningEffort',
      OpenAIReasoningEffort.values,
      (value) => value.value,
      snakeKey: 'reasoning_effort',
      path: _path(namespace, 'reasoningEffort'),
    ),
    maxCompletionTokens: _optionalInt(
      values,
      'maxCompletionTokens',
      snakeKey: 'max_completion_tokens',
      path: _path(namespace, 'maxCompletionTokens'),
    ),
    forceReasoning: _optionalBool(
      values,
      'forceReasoning',
      snakeKey: 'force_reasoning',
      path: _path(namespace, 'forceReasoning'),
    ),
    logprobs: _parseOpenAILogProbs(
      _lookup(values, 'logprobs'),
      path: _path(namespace, 'logprobs'),
    ),
    include: _optionalEnumListByWireValue(
      values,
      'include',
      OpenAIResponsesInclude.values,
      (value) => value.value,
      path: _path(namespace, 'include'),
    ),
    promptCacheKey: _optionalString(
      values,
      'promptCacheKey',
      snakeKey: 'prompt_cache_key',
      path: _path(namespace, 'promptCacheKey'),
    ),
    promptCacheRetention: _optionalEnumByWireValue(
      values,
      'promptCacheRetention',
      OpenAIPromptCacheRetention.values,
      (value) => value.value,
      snakeKey: 'prompt_cache_retention',
      path: _path(namespace, 'promptCacheRetention'),
    ),
    safetyIdentifier: _optionalString(
      values,
      'safetyIdentifier',
      snakeKey: 'safety_identifier',
      path: _path(namespace, 'safetyIdentifier'),
    ),
    responseFormat: _parseOpenAIJsonSchemaResponseFormat(
      _lookup(values, 'responseFormat', snakeKey: 'response_format'),
      path: _path(namespace, 'responseFormat'),
    ),
  );
}

OpenAIGenerateTextOptions mergeOpenAIGenerateTextOptions({
  required OpenAIGenerateTextOptions base,
  OpenAIGenerateTextOptions? override,
}) {
  if (override == null) {
    return base;
  }

  return base.copyWith(
    previousResponseId: override.previousResponseId ?? base.previousResponseId,
    conversation: override.conversation ?? base.conversation,
    store: override.store ?? base.store,
    parallelToolCalls: override.parallelToolCalls ?? base.parallelToolCalls,
    serviceTier: override.serviceTier ?? base.serviceTier,
    verbosity: override.verbosity ?? base.verbosity,
    instructions: override.instructions ?? base.instructions,
    maxToolCalls: override.maxToolCalls ?? base.maxToolCalls,
    metadata: override.metadata ?? base.metadata,
    truncation: override.truncation ?? base.truncation,
    user: override.user ?? base.user,
    systemMessageMode: override.systemMessageMode ?? base.systemMessageMode,
    reasoningEffort: override.reasoningEffort ?? base.reasoningEffort,
    maxCompletionTokens:
        override.maxCompletionTokens ?? base.maxCompletionTokens,
    forceReasoning: override.forceReasoning ?? base.forceReasoning,
    logprobs: override.logprobs ?? base.logprobs,
    include: override.include ?? base.include,
    promptCacheKey: override.promptCacheKey ?? base.promptCacheKey,
    promptCacheRetention:
        override.promptCacheRetention ?? base.promptCacheRetention,
    safetyIdentifier: override.safetyIdentifier ?? base.safetyIdentifier,
    builtInTools: override.builtInTools ?? base.builtInTools,
    responseFormat: override.responseFormat ?? base.responseFormat,
  );
}

DeepSeekGenerateTextOptions? resolveDeepSeekGenerateTextOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typedOptions = typedProviderOptionsFromInvocationOptions(options);
  final typed =
      typedOptions is DeepSeekGenerateTextOptions ? typedOptions : null;
  final bag = providerOptionsBagFromInvocationOptions(options);
  final bagOptions = parseDeepSeekGenerateTextOptionsBag(bag);

  if (typed == null) {
    return bagOptions;
  }

  final commonFromBag = parseOpenAIGenerateTextOptionsBag(bag);
  return DeepSeekGenerateTextOptions(
    common: mergeOpenAIGenerateTextOptions(
      base: commonFromBag,
      override: typed.common,
    ),
    logprobs: typed.logprobs ?? bagOptions?.logprobs,
    topLogprobs: typed.topLogprobs ?? bagOptions?.topLogprobs,
    frequencyPenalty: typed.frequencyPenalty ?? bagOptions?.frequencyPenalty,
    presencePenalty: typed.presencePenalty ?? bagOptions?.presencePenalty,
    responseFormat: typed.responseFormat ?? bagOptions?.responseFormat,
  );
}

ProviderOptionsBag? openAIGenerateTextOptionsToProviderOptionsBag(
  OpenAIGenerateTextOptions options, {
  String namespace = openAIProviderOptionsNamespace,
}) {
  return ProviderOptionsBag.forProvider(namespace, {
    'previous_response_id': options.previousResponseId,
    'conversation': options.conversation,
    'store': options.store,
    'parallel_tool_calls': options.parallelToolCalls,
    'service_tier': options.serviceTier,
    'verbosity': options.verbosity,
    'instructions': options.instructions,
    'max_tool_calls': options.maxToolCalls,
    'metadata': options.metadata,
    'truncation': options.truncation?.value,
    'user': options.user,
    'system_message_mode': options.systemMessageMode?.value,
    'reasoning_effort': options.reasoningEffort?.value,
    'max_completion_tokens': options.maxCompletionTokens,
    'force_reasoning': options.forceReasoning,
    'logprobs': _encodeOpenAILogProbs(options.logprobs),
    'include': options.include
        ?.map((include) => include.value)
        .toList(growable: false),
    'prompt_cache_key': options.promptCacheKey,
    'prompt_cache_retention': options.promptCacheRetention?.value,
    'safety_identifier': options.safetyIdentifier,
    'response_format': options.responseFormat?.toJsonSchema(),
  });
}

DeepSeekGenerateTextOptions? parseDeepSeekGenerateTextOptionsBag(
  ProviderOptionsBag? bag,
) {
  final values = bag?.namespace(deepSeekProviderOptionsNamespace);
  final common = parseOpenAIGenerateTextOptionsBag(bag);

  if ((values == null || values.isEmpty) && _isEmptyOpenAIOptions(common)) {
    return null;
  }

  return DeepSeekGenerateTextOptions(
    common: common,
    logprobs: values == null
        ? null
        : _optionalBool(
            values,
            'logprobs',
            path: _path(deepSeekProviderOptionsNamespace, 'logprobs'),
          ),
    topLogprobs: values == null
        ? null
        : _optionalInt(
            values,
            'topLogprobs',
            snakeKey: 'top_logprobs',
            path: _path(deepSeekProviderOptionsNamespace, 'topLogprobs'),
          ),
    frequencyPenalty: values == null
        ? null
        : _optionalDouble(
            values,
            'frequencyPenalty',
            snakeKey: 'frequency_penalty',
            path: _path(deepSeekProviderOptionsNamespace, 'frequencyPenalty'),
          ),
    presencePenalty: values == null
        ? null
        : _optionalDouble(
            values,
            'presencePenalty',
            snakeKey: 'presence_penalty',
            path: _path(deepSeekProviderOptionsNamespace, 'presencePenalty'),
          ),
    responseFormat: values == null
        ? null
        : _optionalMap(
            values,
            'responseFormat',
            snakeKey: 'response_format',
            path: _path(deepSeekProviderOptionsNamespace, 'responseFormat'),
          ),
  );
}

OpenRouterGenerateTextOptions?
    resolveOpenRouterGenerateTextOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typedOptions = typedProviderOptionsFromInvocationOptions(options);
  final typed =
      typedOptions is OpenRouterGenerateTextOptions ? typedOptions : null;
  final bag = providerOptionsBagFromInvocationOptions(options);
  final bagOptions = parseOpenRouterGenerateTextOptionsBag(bag);

  if (typed == null) {
    return bagOptions;
  }

  final commonFromBag = parseOpenAIGenerateTextOptionsBag(bag);
  return OpenRouterGenerateTextOptions(
    common: mergeOpenAIGenerateTextOptions(
      base: commonFromBag,
      override: typed.common,
    ),
    search: typed.search ?? bagOptions?.search,
  );
}

OpenRouterGenerateTextOptions? parseOpenRouterGenerateTextOptionsBag(
  ProviderOptionsBag? bag,
) {
  final values = bag?.namespace(openRouterProviderOptionsNamespace);
  final common = parseOpenAIGenerateTextOptionsBag(bag);
  final search = values == null
      ? null
      : _parseOpenRouterSearchOptions(
          _lookup(values, 'search'),
          path: _path(openRouterProviderOptionsNamespace, 'search'),
        );

  if (search == null && _isEmptyOpenAIOptions(common)) {
    return null;
  }

  return OpenRouterGenerateTextOptions(
    common: common,
    search: search,
  );
}

XAIGenerateTextOptions? resolveXAIGenerateTextOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typedOptions = typedProviderOptionsFromInvocationOptions(options);
  final typed = typedOptions is XAIGenerateTextOptions ? typedOptions : null;
  final bag = providerOptionsBagFromInvocationOptions(options);
  final bagOptions = parseXAIGenerateTextOptionsBag(bag);

  if (typed == null) {
    return bagOptions;
  }

  final commonFromBag = parseOpenAIGenerateTextOptionsBag(bag);
  return XAIGenerateTextOptions(
    common: mergeOpenAIGenerateTextOptions(
      base: commonFromBag,
      override: typed.common,
    ),
    search: typed.search ?? bagOptions?.search,
  );
}

XAIGenerateTextOptions? parseXAIGenerateTextOptionsBag(
  ProviderOptionsBag? bag,
) {
  final values = bag?.namespace(xaiProviderOptionsNamespace);
  final common = parseOpenAIGenerateTextOptionsBag(bag);
  final search = values == null
      ? null
      : _parseXAILiveSearchOptions(
          _lookup(values, 'search'),
          path: _path(xaiProviderOptionsNamespace, 'search'),
        );

  if (search == null && _isEmptyOpenAIOptions(common)) {
    return null;
  }

  return XAIGenerateTextOptions(
    common: common,
    search: search,
  );
}

OpenAIEmbedOptions? resolveOpenAIEmbedOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typed = resolveProviderInvocationOptions<OpenAIEmbedOptions>(
    options,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'OpenAIEmbedOptions for OpenAI-family embedding models',
  );
  final bagOptions = parseOpenAIEmbedOptionsBag(
    providerOptionsBagFromInvocationOptions(options),
  );

  if (typed == null) {
    return bagOptions;
  }

  return OpenAIEmbedOptions(
    encodingFormat: typed.encodingFormat ?? bagOptions?.encodingFormat,
    user: typed.user ?? bagOptions?.user,
  );
}

OpenAIEmbedOptions? parseOpenAIEmbedOptionsBag(ProviderOptionsBag? bag) {
  final values = bag?.namespace(openAIProviderOptionsNamespace);
  if (values == null || values.isEmpty) {
    return null;
  }

  final options = OpenAIEmbedOptions(
    encodingFormat: _optionalString(
      values,
      'encodingFormat',
      snakeKey: 'encoding_format',
      path: _path(openAIProviderOptionsNamespace, 'encodingFormat'),
    ),
    user: _optionalString(
      values,
      'user',
      path: _path(openAIProviderOptionsNamespace, 'user'),
    ),
  );

  return options.encodingFormat == null && options.user == null
      ? null
      : options;
}

ProviderOptionsBag? openAIEmbedOptionsToProviderOptionsBag(
  OpenAIEmbedOptions options,
) {
  return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
    'encoding_format': options.encodingFormat,
    'user': options.user,
  });
}

OpenAIImageOptions? resolveOpenAIImageOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typed = resolveProviderInvocationOptions<OpenAIImageOptions>(
    options,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'OpenAIImageOptions for OpenAI-family image models',
  );
  final bagOptions = parseOpenAIImageOptionsBag(
    providerOptionsBagFromInvocationOptions(options),
  );

  if (typed == null) {
    return bagOptions;
  }

  return OpenAIImageOptions(
    style: typed.style ?? bagOptions?.style,
    quality: typed.quality ?? bagOptions?.quality,
    background: typed.background ?? bagOptions?.background,
    moderation: typed.moderation ?? bagOptions?.moderation,
    outputFormat: typed.outputFormat ?? bagOptions?.outputFormat,
    outputCompression: typed.outputCompression ?? bagOptions?.outputCompression,
    responseFormat: typed.responseFormat ?? bagOptions?.responseFormat,
    user: typed.user ?? bagOptions?.user,
  );
}

OpenAIImageOptions? parseOpenAIImageOptionsBag(ProviderOptionsBag? bag) {
  final values = bag?.namespace(openAIProviderOptionsNamespace);
  if (values == null || values.isEmpty) {
    return null;
  }

  final options = OpenAIImageOptions(
    style: _optionalEnumByWireValue(
      values,
      'style',
      OpenAIImageStyle.values,
      (value) => value.value,
      path: _path(openAIProviderOptionsNamespace, 'style'),
    ),
    quality: _optionalEnumByWireValue(
      values,
      'quality',
      OpenAIImageQuality.values,
      (value) => value.value,
      path: _path(openAIProviderOptionsNamespace, 'quality'),
    ),
    background: _optionalEnumByWireValue(
      values,
      'background',
      OpenAIImageBackground.values,
      (value) => value.value,
      path: _path(openAIProviderOptionsNamespace, 'background'),
    ),
    moderation: _optionalEnumByWireValue(
      values,
      'moderation',
      OpenAIImageModeration.values,
      (value) => value.value,
      path: _path(openAIProviderOptionsNamespace, 'moderation'),
    ),
    outputFormat: _optionalEnumByWireValue(
      values,
      'outputFormat',
      OpenAIImageOutputFormat.values,
      (value) => value.value,
      snakeKey: 'output_format',
      path: _path(openAIProviderOptionsNamespace, 'outputFormat'),
    ),
    outputCompression: _optionalInt(
      values,
      'outputCompression',
      snakeKey: 'output_compression',
      path: _path(openAIProviderOptionsNamespace, 'outputCompression'),
    ),
    responseFormat: _optionalEnumByWireValue(
      values,
      'responseFormat',
      OpenAIImageResponseFormat.values,
      (value) => value.value,
      snakeKey: 'response_format',
      path: _path(openAIProviderOptionsNamespace, 'responseFormat'),
    ),
    user: _optionalString(
      values,
      'user',
      path: _path(openAIProviderOptionsNamespace, 'user'),
    ),
  );

  return _isEmptyOpenAIImageOptions(options) ? null : options;
}

ProviderOptionsBag? openAIImageOptionsToProviderOptionsBag(
  OpenAIImageOptions options,
) {
  return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
    'style': options.style?.value,
    'quality': options.quality?.value,
    'background': options.background?.value,
    'moderation': options.moderation?.value,
    'output_format': options.outputFormat?.value,
    'output_compression': options.outputCompression,
    'response_format': options.responseFormat?.value,
    'user': options.user,
  });
}

OpenAISpeechOptions? resolveOpenAISpeechOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typed = resolveProviderInvocationOptions<OpenAISpeechOptions>(
    options,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'OpenAISpeechOptions for OpenAI-family speech models',
  );
  final bagOptions = parseOpenAISpeechOptionsBag(
    providerOptionsBagFromInvocationOptions(options),
  );

  if (typed == null) {
    return bagOptions;
  }

  return OpenAISpeechOptions(
    outputFormat: typed.outputFormat ?? bagOptions?.outputFormat,
    instructions: typed.instructions ?? bagOptions?.instructions,
    speed: typed.speed ?? bagOptions?.speed,
    language: typed.language ?? bagOptions?.language,
  );
}

OpenAISpeechOptions? parseOpenAISpeechOptionsBag(ProviderOptionsBag? bag) {
  final values = bag?.namespace(openAIProviderOptionsNamespace);
  if (values == null || values.isEmpty) {
    return null;
  }

  final options = OpenAISpeechOptions(
    outputFormat: _optionalString(
      values,
      'outputFormat',
      snakeKey: 'output_format',
      path: _path(openAIProviderOptionsNamespace, 'outputFormat'),
    ),
    instructions: _optionalString(
      values,
      'instructions',
      path: _path(openAIProviderOptionsNamespace, 'instructions'),
    ),
    speed: _optionalDouble(
      values,
      'speed',
      path: _path(openAIProviderOptionsNamespace, 'speed'),
    ),
    language: _optionalString(
      values,
      'language',
      path: _path(openAIProviderOptionsNamespace, 'language'),
    ),
  );

  return options.outputFormat == null &&
          options.instructions == null &&
          options.speed == null &&
          options.language == null
      ? null
      : options;
}

ProviderOptionsBag? openAISpeechOptionsToProviderOptionsBag(
  OpenAISpeechOptions options,
) {
  return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
    'output_format': options.outputFormat,
    'instructions': options.instructions,
    'speed': options.speed,
    'language': options.language,
  });
}

OpenAITranscriptionOptions? resolveOpenAITranscriptionOptionsFromInvocation(
  ProviderInvocationOptions? options,
) {
  final typed = resolveProviderInvocationOptions<OpenAITranscriptionOptions>(
    options,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName:
        'OpenAITranscriptionOptions for OpenAI-family transcription models',
  );
  final bagOptions = parseOpenAITranscriptionOptionsBag(
    providerOptionsBagFromInvocationOptions(options),
  );

  if (typed == null) {
    return bagOptions;
  }

  return OpenAITranscriptionOptions(
    include: typed.include.isNotEmpty
        ? typed.include
        : bagOptions?.include ?? const [],
    language: typed.language ?? bagOptions?.language,
    prompt: typed.prompt ?? bagOptions?.prompt,
    temperature: typed.temperature ?? bagOptions?.temperature,
    responseFormat: typed.responseFormat ?? bagOptions?.responseFormat,
    timestampGranularities: typed.timestampGranularities.isNotEmpty
        ? typed.timestampGranularities
        : bagOptions?.timestampGranularities ?? const [],
  );
}

OpenAITranscriptionOptions? parseOpenAITranscriptionOptionsBag(
  ProviderOptionsBag? bag,
) {
  final values = bag?.namespace(openAIProviderOptionsNamespace);
  if (values == null || values.isEmpty) {
    return null;
  }

  final options = OpenAITranscriptionOptions(
    include: _optionalStringList(
          values,
          'include',
          path: _path(openAIProviderOptionsNamespace, 'include'),
        ) ??
        const [],
    language: _optionalString(
      values,
      'language',
      path: _path(openAIProviderOptionsNamespace, 'language'),
    ),
    prompt: _optionalString(
      values,
      'prompt',
      path: _path(openAIProviderOptionsNamespace, 'prompt'),
    ),
    temperature: _optionalDouble(
      values,
      'temperature',
      path: _path(openAIProviderOptionsNamespace, 'temperature'),
    ),
    responseFormat: _optionalEnumByWireValue(
      values,
      'responseFormat',
      OpenAITranscriptionResponseFormat.values,
      (value) => value.value,
      snakeKey: 'response_format',
      path: _path(openAIProviderOptionsNamespace, 'responseFormat'),
    ),
    timestampGranularities: _optionalEnumListByWireValue(
          values,
          'timestampGranularities',
          OpenAITranscriptionTimestampGranularity.values,
          (value) => value.value,
          snakeKey: 'timestamp_granularities',
          path: _path(openAIProviderOptionsNamespace, 'timestampGranularities'),
        ) ??
        const [],
  );

  return _isEmptyOpenAITranscriptionOptions(options) ? null : options;
}

ProviderOptionsBag? openAITranscriptionOptionsToProviderOptionsBag(
  OpenAITranscriptionOptions options,
) {
  return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
    'include': options.include.isEmpty ? null : options.include,
    'language': options.language,
    'prompt': options.prompt,
    'temperature': options.temperature,
    'response_format': options.responseFormat?.value,
    'timestamp_granularities': options.timestampGranularities.isEmpty
        ? null
        : options.timestampGranularities
            .map((granularity) => granularity.value)
            .toList(growable: false),
  });
}

bool _isEmptyOpenAIOptions(OpenAIGenerateTextOptions options) {
  return options.previousResponseId == null &&
      options.conversation == null &&
      options.store == null &&
      options.parallelToolCalls == null &&
      options.serviceTier == null &&
      options.verbosity == null &&
      options.instructions == null &&
      options.maxToolCalls == null &&
      options.metadata == null &&
      options.truncation == null &&
      options.user == null &&
      options.systemMessageMode == null &&
      options.reasoningEffort == null &&
      options.maxCompletionTokens == null &&
      options.forceReasoning == null &&
      options.logprobs == null &&
      (options.include == null || options.include!.isEmpty) &&
      options.promptCacheKey == null &&
      options.promptCacheRetention == null &&
      options.safetyIdentifier == null &&
      (options.builtInTools == null || options.builtInTools!.isEmpty) &&
      options.responseFormat == null;
}

bool _isEmptyOpenAIImageOptions(OpenAIImageOptions options) {
  return options.style == null &&
      options.quality == null &&
      options.background == null &&
      options.moderation == null &&
      options.outputFormat == null &&
      options.outputCompression == null &&
      options.responseFormat == null &&
      options.user == null;
}

bool _isEmptyOpenAITranscriptionOptions(OpenAITranscriptionOptions options) {
  return options.include.isEmpty &&
      options.language == null &&
      options.prompt == null &&
      options.temperature == null &&
      options.responseFormat == null &&
      options.timestampGranularities.isEmpty;
}

OpenAILogProbs? _parseOpenAILogProbs(
  Object? value, {
  required String path,
}) {
  return switch (value) {
    null => null,
    bool() when value == true => const OpenAILogProbs.enabled(),
    int() => OpenAILogProbs.top(value),
    Map() => _parseOpenAILogProbsObject(value, path: path),
    _ => throw FormatException('Expected bool, int, or JSON object at $path.'),
  };
}

Object? _encodeOpenAILogProbs(OpenAILogProbs? value) {
  if (value == null) {
    return null;
  }

  return value.topLogProbs == null
      ? true
      : {
          'top_logprobs': value.topLogProbs,
        };
}

OpenAILogProbs _parseOpenAILogProbsObject(
  Map value, {
  required String path,
}) {
  final map = asJsonMap(value, path: path);
  final enabled = _optionalBool(map, 'enabled', path: '$path.enabled');
  final topLogProbs = _optionalInt(
    map,
    'topLogProbs',
    snakeKey: 'top_logprobs',
    path: '$path.topLogProbs',
  );

  if (topLogProbs != null) {
    return OpenAILogProbs.top(topLogProbs);
  }

  if (enabled == false) {
    throw FormatException('Expected enabled=true at $path.enabled.');
  }

  return const OpenAILogProbs.enabled();
}

OpenAIJsonSchemaResponseFormat? _parseOpenAIJsonSchemaResponseFormat(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final map = asJsonMap(value, path: path);
  final jsonSchema = map['json_schema'] is Map
      ? asJsonMap(map['json_schema'], path: '$path.json_schema')
      : map;

  return OpenAIJsonSchemaResponseFormat(
    name: asJsonString(jsonSchema['name'], path: '$path.name'),
    description: asNullableJsonString(
      jsonSchema['description'],
      path: '$path.description',
    ),
    schema: jsonSchema['schema'] == null
        ? null
        : asJsonMap(jsonSchema['schema'], path: '$path.schema'),
    strict: asNullableJsonBool(jsonSchema['strict'], path: '$path.strict'),
  );
}

OpenRouterSearchOptions? _parseOpenRouterSearchOptions(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final mode = value is String
      ? value
      : asJsonString(asJsonMap(value, path: path)['mode'], path: '$path.mode');

  return switch (mode) {
    'onlineModel' ||
    'online_model' ||
    'online' =>
      const OpenRouterSearchOptions.onlineModel(),
    _ => throw FormatException('Unsupported OpenRouter search mode at $path.'),
  };
}

XAILiveSearchOptions? _parseXAILiveSearchOptions(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final map = asJsonMap(value, path: path);
  return XAILiveSearchOptions(
    mode: _optionalEnumByWireValue(
          map,
          'mode',
          XAISearchMode.values,
          (value) => value.wireValue,
          path: '$path.mode',
        ) ??
        XAISearchMode.auto,
    returnCitations: _optionalBool(
          map,
          'returnCitations',
          snakeKey: 'return_citations',
          path: '$path.returnCitations',
        ) ??
        true,
    fromDate: _optionalDate(
      map,
      'fromDate',
      snakeKey: 'from_date',
      path: '$path.fromDate',
    ),
    toDate: _optionalDate(
      map,
      'toDate',
      snakeKey: 'to_date',
      path: '$path.toDate',
    ),
    maxSearchResults: _optionalInt(
      map,
      'maxSearchResults',
      snakeKey: 'max_search_results',
      path: '$path.maxSearchResults',
    ),
  );
}

DateTime? _optionalDate(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return DateTime.parse(asJsonString(raw, path: path));
}

T? _optionalEnumByWireValue<T extends Object>(
  JsonMap values,
  String key,
  List<T> allowed,
  String Function(T value) wireValue, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  final text = asJsonString(raw, path: path);
  for (final value in allowed) {
    if (wireValue(value) == text) {
      return value;
    }
  }

  throw FormatException('Unsupported enum value "$text" at $path.');
}

List<T>? _optionalEnumListByWireValue<T extends Object>(
  JsonMap values,
  String key,
  List<T> allowed,
  String Function(T value) wireValue, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return asJsonList(raw, path: path)
      .asMap()
      .entries
      .map(
        (entry) => _enumByWireValue(
          asJsonString(entry.value, path: '$path[${entry.key}]'),
          allowed,
          wireValue,
          path: '$path[${entry.key}]',
        ),
      )
      .toList(growable: false);
}

T _enumByWireValue<T extends Object>(
  String text,
  List<T> allowed,
  String Function(T value) wireValue, {
  required String path,
}) {
  for (final value in allowed) {
    if (wireValue(value) == text) {
      return value;
    }
  }

  throw FormatException('Unsupported enum value "$text" at $path.');
}

String? _optionalString(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  return asNullableJsonString(raw, path: path);
}

bool? _optionalBool(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  return asNullableJsonBool(raw, path: path);
}

int? _optionalInt(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  return asNullableJsonInt(raw, path: path);
}

double? _optionalDouble(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  if (raw is num) {
    return raw.toDouble();
  }

  throw FormatException('Expected number at $path.');
}

JsonMap? _optionalMap(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return asJsonMap(raw, path: path);
}

List<String>? _optionalStringList(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return asJsonList(raw, path: path)
      .asMap()
      .entries
      .map((entry) => asJsonString(entry.value, path: '$path[${entry.key}]'))
      .toList(growable: false);
}

Object? _lookup(
  JsonMap values,
  String key, {
  String? snakeKey,
}) {
  if (values.containsKey(key)) {
    return values[key];
  }

  if (snakeKey != null && values.containsKey(snakeKey)) {
    return values[snakeKey];
  }

  return null;
}

String _path(String namespace, String key) =>
    '\$.providerOptions.$namespace.$key';
