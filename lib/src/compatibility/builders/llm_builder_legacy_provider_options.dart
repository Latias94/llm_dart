import '../../../builder/llm_builder.dart';
import '../config/legacy_provider_options.dart';

/// Stores a legacy builder callback option under the provider-scoped
/// `providerOptions` compatibility bag.
void setLegacyBuilderProviderOption(
  LLMBuilder builder,
  String namespace,
  String key,
  dynamic value,
) {
  final providerOptions = setLegacyProviderOption(
    builder.currentConfig,
    namespace,
    key,
    value,
  );

  builder.legacyExtension(legacyProviderOptionsBagKey, providerOptions);
}
