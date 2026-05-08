import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;

import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../providers/openai/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import 'openai_family_compat_openai_config.dart';

OpenAIConfig toCompatLegacyOpenRouterConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openrouter,
  );
  var model = config.model;
  final webSearchEnabled =
      options.getWithFlatFallback<bool>(LegacyExtensionKeys.webSearchEnabled) ==
          true;
  final webSearchConfig = options.getWithFlatFallback<WebSearchConfig>(
      LegacyExtensionKeys.webSearchConfig);
  if ((webSearchEnabled || webSearchConfig != null) &&
      !model.endsWith(':online')) {
    model = '$model:online';
  }

  return createCompatOpenAIFamilyConfig(
    config: config,
    model: model,
    options: options,
  );
}

core.ProviderModelOptions buildCompatOpenRouterModelSettings(
  LLMConfig config,
) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openrouter,
  );
  final webSearchEnabled =
      options.getWithFlatFallback<bool>(LegacyExtensionKeys.webSearchEnabled) ==
          true;
  final webSearchConfig = options.getWithFlatFallback<WebSearchConfig>(
      LegacyExtensionKeys.webSearchConfig);
  if ((webSearchEnabled || webSearchConfig != null) &&
      !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}
