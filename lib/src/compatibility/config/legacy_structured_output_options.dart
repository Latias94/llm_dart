import '../../../core/config.dart';
import '../../../models/tool_models.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

StructuredOutputFormat? legacyStructuredOutputFormat(
  LLMConfig config, {
  String? providerOptionsNamespace,
}) {
  if (providerOptionsNamespace != null) {
    return legacyProviderOptionView(
      config,
      providerOptionsNamespace,
    ).getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    );
  }

  return config.getExtension<StructuredOutputFormat>(
    LegacyExtensionKeys.jsonSchema,
  );
}
