import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../language/openai_generate_text_options.dart';
import 'deepseek_options.dart';
import 'openai_provider_options_bag.dart';
import 'openrouter_options.dart';
import 'xai_options.dart';

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
  return resolveDeepSeekGenerateTextOptionsFromInvocation(options);
}

OpenRouterGenerateTextOptions? resolveOpenRouterGenerateTextInvocationOptions(
  ProviderInvocationOptions? options,
) {
  return resolveOpenRouterGenerateTextOptionsFromInvocation(options);
}

XAIGenerateTextOptions? resolveXAIGenerateTextInvocationOptions(
  ProviderInvocationOptions? options,
) {
  return resolveXAIGenerateTextOptionsFromInvocation(options);
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
