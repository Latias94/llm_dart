part of 'openai_provider_options_bag.dart';

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
