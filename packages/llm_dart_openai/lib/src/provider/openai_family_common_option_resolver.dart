import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'deepseek_options.dart';
import 'openai_family_option_resolver_base.dart';
import '../language/openai_family_shared_response_format.dart';
import '../language/openai_generate_text_options.dart';
import 'openai_model_settings.dart';
import 'openrouter_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';
import 'xai_options.dart';

class CommonOpenAIOptionResolver extends OpenAIFamilyOptionResolver {
  const CommonOpenAIOptionResolver();

  @override
  ResolvedOpenAIChatModelSettings resolveModelSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is OpenAIChatModelSettings) {
      return ResolvedOpenAIChatModelSettings(
        common: settings,
      );
    }

    if (settings is OpenRouterChatModelSettings) {
      throw ArgumentError.value(
        settings,
        'settings',
        'OpenRouterChatModelSettings are only valid for OpenRouter language models.',
      );
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected OpenAIChatModelSettings or profile-specific OpenAI-family model settings.',
    );
  }

  @override
  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  }) {
    final common = resolveCommonInvocationOptions(options);

    return ResolvedOpenAIGenerateTextOptions(
      common: mergeOpenAIFamilyCommonOptions(
        common: common,
        sharedResponseFormat: sharedResponseFormat,
        modelSettings: modelSettings.common,
      ),
    );
  }

  @override
  String resolveRequestModelId({
    required String modelId,
    required ResolvedOpenAIChatModelSettings modelSettings,
    required ResolvedOpenAIGenerateTextOptions invocationOptions,
  }) {
    return modelId;
  }

  OpenAIGenerateTextOptions resolveCommonInvocationOptions(
    ProviderInvocationOptions? options,
  ) {
    if (options == null) {
      return const OpenAIGenerateTextOptions();
    }

    if (options is OpenAIGenerateTextOptions) {
      return options;
    }

    throwWrongOpenAIFamilyProviderOptions(options);
  }
}

OpenAIGenerateTextOptions mergeOpenAIFamilyCommonOptions({
  required OpenAIGenerateTextOptions common,
  required ResponseFormat? sharedResponseFormat,
  required OpenAIChatModelSettings modelSettings,
  DeepSeekGenerateTextOptions? deepseekOptions,
}) {
  final resolvedSharedResponseFormat =
      resolveOpenAIFamilySharedResponseFormat(sharedResponseFormat);

  if (sharedResponseFormat != null && common.responseFormat != null) {
    throw ArgumentError(
      'GenerateTextOptions.responseFormat and OpenAIGenerateTextOptions.responseFormat cannot both be set.',
    );
  }

  if (deepseekOptions?.responseFormat != null &&
      (sharedResponseFormat != null || common.responseFormat != null)) {
    throw ArgumentError(
      'DeepSeekGenerateTextOptions.responseFormat cannot be combined with shared or OpenAI JSON-schema responseFormat.',
    );
  }

  if (common.builtInTools == null && modelSettings.builtInTools.isNotEmpty) {
    common = common.copyWith(
      builtInTools: modelSettings.builtInTools,
    );
  }

  if (resolvedSharedResponseFormat != null) {
    common = common.copyWith(
      responseFormat: resolvedSharedResponseFormat,
    );
  }

  return common;
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
