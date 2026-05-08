part of 'llm_builder.dart';

/// Stores a legacy builder callback option under the provider-scoped
/// `providerOptions` compatibility bag.
///
/// This is intentionally narrower than arbitrary root extension mutation: it
/// keeps compatibility builder callbacks provider-owned while the old root
/// shortcut surface is being removed.
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

  builder._setExtension(legacyProviderOptionsBagKey, providerOptions);
}
