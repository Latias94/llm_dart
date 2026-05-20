import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_common_option_resolver.dart';
import 'openrouter_model_id_policy.dart';
import 'openrouter_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';

final class OpenRouterOptionResolver extends CommonOpenAIOptionResolver {
  const OpenRouterOptionResolver();

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
        common: mergeOpenAIFamilyCommonOptions(
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
