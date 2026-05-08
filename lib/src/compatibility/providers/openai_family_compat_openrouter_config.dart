import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;

import '../../../core/config.dart';
import '../../../providers/openai/config.dart';
import '../config/legacy_provider_options.dart';
import '../config/legacy_web_search_options.dart';
import 'openai_family_compat_openai_config.dart';

OpenAIConfig toCompatLegacyOpenRouterConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openrouter,
  );
  var model = config.model;
  final webSearchOptions = legacyWebSearchOptions(options);
  if (webSearchOptions.hasSearchIntent && !model.endsWith(':online')) {
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
  final webSearchOptions = legacyWebSearchOptions(options);
  if (webSearchOptions.hasSearchIntent && !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}
