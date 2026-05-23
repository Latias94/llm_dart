part of 'openai_provider_options_bag.dart';

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
