import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'deepseek_options.dart';
import 'openai_family_profile.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openrouter_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';
import 'xai_options.dart';

abstract class OpenAIFamilyOptionResolver {
  const OpenAIFamilyOptionResolver();

  ResolvedOpenAIChatModelSettings resolveModelSettings(
    ProviderModelOptions settings,
  );

  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  });

  String resolveRequestModelId({
    required String modelId,
    required ResolvedOpenAIChatModelSettings modelSettings,
    required ResolvedOpenAIGenerateTextOptions invocationOptions,
  });
}

OpenAIFamilyOptionResolver openAIFamilyOptionResolverFor(
  OpenAIFamilyProfile profile,
) {
  return switch (profile) {
    DeepSeekProfile() => const _DeepSeekOptionResolver(),
    OpenRouterProfile() => const _OpenRouterOptionResolver(),
    XAIProfile() => const _XAIOptionResolver(),
    _ => const _CommonOpenAIOptionResolver(),
  };
}

class _CommonOpenAIOptionResolver extends OpenAIFamilyOptionResolver {
  const _CommonOpenAIOptionResolver();

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
    final common = _resolveCommonInvocationOptions(options);

    return ResolvedOpenAIGenerateTextOptions(
      common: _mergeCommonOptions(
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

  OpenAIGenerateTextOptions _resolveCommonInvocationOptions(
    ProviderInvocationOptions? options,
  ) {
    if (options == null) {
      return const OpenAIGenerateTextOptions();
    }

    if (options is OpenAIGenerateTextOptions) {
      return options;
    }

    _throwWrongProviderOptions(options);
  }
}

final class _DeepSeekOptionResolver extends _CommonOpenAIOptionResolver {
  const _DeepSeekOptionResolver();

  @override
  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  }) {
    if (options is DeepSeekGenerateTextOptions) {
      return ResolvedOpenAIGenerateTextOptions(
        common: _mergeCommonOptions(
          common: options.common,
          sharedResponseFormat: sharedResponseFormat,
          modelSettings: modelSettings.common,
          deepseekOptions: options,
        ),
        deepseek: options,
      );
    }

    return super.resolveInvocationOptions(
      options: options,
      sharedResponseFormat: sharedResponseFormat,
      modelSettings: modelSettings,
    );
  }
}

final class _OpenRouterOptionResolver extends _CommonOpenAIOptionResolver {
  const _OpenRouterOptionResolver();

  @override
  ResolvedOpenAIChatModelSettings resolveModelSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is OpenRouterChatModelSettings) {
      return ResolvedOpenAIChatModelSettings(
        common: settings.common,
        openRouterSearch: settings.search,
      );
    }

    return super.resolveModelSettings(settings);
  }

  @override
  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  }) {
    if (options is OpenRouterGenerateTextOptions) {
      return ResolvedOpenAIGenerateTextOptions(
        common: _mergeCommonOptions(
          common: options.common,
          sharedResponseFormat: sharedResponseFormat,
          modelSettings: modelSettings.common,
        ),
        openRouterSearch: options.search,
      );
    }

    return super.resolveInvocationOptions(
      options: options,
      sharedResponseFormat: sharedResponseFormat,
      modelSettings: modelSettings,
    );
  }

  @override
  String resolveRequestModelId({
    required String modelId,
    required ResolvedOpenAIChatModelSettings modelSettings,
    required ResolvedOpenAIGenerateTextOptions invocationOptions,
  }) {
    final search =
        invocationOptions.openRouterSearch ?? modelSettings.openRouterSearch;
    if (search == null) {
      return modelId;
    }

    return switch (search.mode) {
      OpenRouterSearchMode.onlineModel => resolveOpenRouterOnlineModelId(
          modelId,
        ),
    };
  }
}

final class _XAIOptionResolver extends _CommonOpenAIOptionResolver {
  const _XAIOptionResolver();

  @override
  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  }) {
    if (options is XAIGenerateTextOptions) {
      return ResolvedOpenAIGenerateTextOptions(
        common: _mergeCommonOptions(
          common: options.common,
          sharedResponseFormat: sharedResponseFormat,
          modelSettings: modelSettings.common,
        ),
        xaiSearch: options.search,
      );
    }

    return super.resolveInvocationOptions(
      options: options,
      sharedResponseFormat: sharedResponseFormat,
      modelSettings: modelSettings,
    );
  }
}

OpenAIGenerateTextOptions _mergeCommonOptions({
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

Never _throwWrongProviderOptions(ProviderInvocationOptions options) {
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

String resolveOpenRouterOnlineModelId(String modelId) {
  if (modelId.endsWith(':online')) {
    return modelId;
  }

  if (modelId.contains('deepseek-r1')) {
    throw UnsupportedError(
      'OpenRouter online-model shaping is not supported for DeepSeek R1 traffic.',
    );
  }

  return '$modelId:online';
}

OpenAIJsonSchemaResponseFormat? resolveOpenAIFamilySharedResponseFormat(
  ResponseFormat? responseFormat,
) {
  return switch (responseFormat) {
    null || TextResponseFormat() => null,
    JsonResponseFormat(
      schema: final schema,
      name: final name,
      description: final description,
      strict: final strict,
    ) =>
      OpenAIJsonSchemaResponseFormat(
        name: name ?? 'structured_output',
        description: description,
        schema: schema.toJson(),
        strict: strict,
      ),
  };
}
