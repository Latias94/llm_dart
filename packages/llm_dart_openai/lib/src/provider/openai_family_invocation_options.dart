import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../embedding/openai_embedding_options.dart';
import '../image/openai_image_options.dart';
import '../speech/openai_speech_options.dart';
import '../transcription/openai_transcription_options.dart';
import '../language/openai_generate_text_options.dart';
import 'deepseek_options.dart';
import 'openai_provider_options_bag.dart';
import 'openrouter_options.dart';
import 'xai_options.dart';

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

  return _mergeOpenAIGenerateTextOptions(
    base: bagOptions,
    override: typed,
  );
}

OpenAIGenerateTextOptions resolveCommonOpenAIGenerateTextInvocationOptions(
  ProviderInvocationOptions? options,
) {
  if (options == null) {
    return const OpenAIGenerateTextOptions();
  }

  final typedOptions = typedProviderOptionsFromInvocationOptions(options);
  if (typedOptions is OpenAIGenerateTextOptions) {
    return resolveOpenAIGenerateTextOptionsFromInvocation(options);
  }

  if (typedOptions == null &&
      providerOptionsBagFromInvocationOptions(options) != null) {
    return resolveOpenAIGenerateTextOptionsFromInvocation(options);
  }

  throwWrongOpenAIFamilyProviderOptions(typedOptions ?? options);
}

DeepSeekGenerateTextOptions? resolveDeepSeekGenerateTextInvocationOptions(
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
    common: _mergeOpenAIGenerateTextOptions(
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

OpenRouterGenerateTextOptions? resolveOpenRouterGenerateTextInvocationOptions(
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
    common: _mergeOpenAIGenerateTextOptions(
      base: commonFromBag,
      override: typed.common,
    ),
    search: typed.search ?? bagOptions?.search,
  );
}

XAIGenerateTextOptions? resolveXAIGenerateTextInvocationOptions(
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
    common: _mergeOpenAIGenerateTextOptions(
      base: commonFromBag,
      override: typed.common,
    ),
    search: typed.search ?? bagOptions?.search,
  );
}

OpenAIEmbedOptions? resolveOpenAIEmbedInvocationOptions(
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

OpenAIImageOptions? resolveOpenAIImageInvocationOptions(
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

OpenAISpeechOptions? resolveOpenAISpeechInvocationOptions(
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

OpenAITranscriptionOptions? resolveOpenAITranscriptionInvocationOptions(
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

Never throwWrongOpenAIFamilyProviderOptions(ProviderInvocationOptions options) {
  if (options is DeepSeekGenerateTextOptions) {
    throw ArgumentError.value(
      options,
      'providerOptions',
      'DeepSeekGenerateTextOptions are only valid for DeepSeek language models.',
    );
  }

  if (options is OpenRouterGenerateTextOptions) {
    throw ArgumentError.value(
      options,
      'providerOptions',
      'OpenRouterGenerateTextOptions are only valid for OpenRouter language models.',
    );
  }

  if (options is XAIGenerateTextOptions) {
    throw ArgumentError.value(
      options,
      'providerOptions',
      'XAIGenerateTextOptions are only valid for xAI language models.',
    );
  }

  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected OpenAIGenerateTextOptions or profile-specific OpenAI-family provider options.',
  );
}

OpenAIGenerateTextOptions _mergeOpenAIGenerateTextOptions({
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
