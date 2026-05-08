import '../../../core/config.dart';

/// Top-level bag key used to stage the legacy root-package migration toward
/// provider-scoped option groups.
const legacyProviderOptionsBagKey = 'providerOptions';

/// Namespaces used inside the transitional legacy `providerOptions` bag.
abstract final class LegacyProviderOptionNamespaces {
  static const openai = 'openai';
  static const openrouter = 'openrouter';
  static const anthropic = 'anthropic';
  static const google = 'google';
  static const ollama = 'ollama';
  static const elevenlabs = 'elevenlabs';
  static const xai = 'xai';
  static const deepseek = 'deepseek';
}

Map<String, dynamic>? legacyProviderOptionsBagOrNull(LLMConfig config) {
  final raw = config.extensions[legacyProviderOptionsBagKey];
  if (raw == null) {
    return null;
  }

  if (raw is Map<String, dynamic>) {
    return Map<String, dynamic>.from(raw);
  }

  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  return null;
}

Map<String, dynamic> legacyProviderOptionsBag(LLMConfig config) =>
    legacyProviderOptionsBagOrNull(config) ?? <String, dynamic>{};

Map<String, dynamic>? legacyProviderOptionsNamespaceOrNull(
  LLMConfig config,
  String namespace,
) {
  final bag = legacyProviderOptionsBagOrNull(config);
  if (bag == null) {
    return null;
  }

  final raw = bag[namespace];
  if (raw == null) {
    return null;
  }

  if (raw is Map<String, dynamic>) {
    return Map<String, dynamic>.from(raw);
  }

  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  return null;
}

Map<String, dynamic> legacyProviderOptionsNamespace(
  LLMConfig config,
  String namespace,
) =>
    legacyProviderOptionsNamespaceOrNull(config, namespace) ??
    <String, dynamic>{};

T? getLegacyProviderOption<T>(
  LLMConfig config,
  String namespace,
  String key, {
  String? fallbackKey,
}) {
  final namespaceOptions = legacyProviderOptionsNamespaceOrNull(
    config,
    namespace,
  );
  if (namespaceOptions != null && namespaceOptions.containsKey(key)) {
    return namespaceOptions[key] as T?;
  }

  return config.getExtension<T>(fallbackKey ?? key);
}

Map<String, dynamic> setLegacyProviderOption(
  LLMConfig config,
  String namespace,
  String key,
  dynamic value,
) {
  final providerOptions = legacyProviderOptionsBag(config);
  final namespaceOptions = legacyProviderOptionsNamespace(config, namespace);

  namespaceOptions[key] = value;
  providerOptions[namespace] = namespaceOptions;

  return providerOptions;
}
