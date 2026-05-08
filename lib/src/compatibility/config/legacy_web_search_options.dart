import '../../../core/web_search.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

final class LegacyWebSearchOptions {
  final bool enabled;
  final WebSearchConfig? config;

  const LegacyWebSearchOptions({
    required this.enabled,
    required this.config,
  });

  bool get hasSearchIntent => enabled || config != null;

  WebSearchConfig? get configOrEnabledDefault {
    final config = this.config;
    if (config != null) {
      return config;
    }

    return enabled ? const WebSearchConfig() : null;
  }
}

LegacyWebSearchOptions legacyWebSearchOptions(
  LegacyProviderOptionView options,
) {
  return LegacyWebSearchOptions(
    enabled: options
            .getWithFlatFallback<bool>(LegacyExtensionKeys.webSearchEnabled) ==
        true,
    config: options.getWithFlatFallback<WebSearchConfig>(
      LegacyExtensionKeys.webSearchConfig,
    ),
  );
}
