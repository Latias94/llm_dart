part of 'legacy_chat_adapter.dart';

StructuredOutputFormat? _resolveCompatStructuredOutputFormat(
  LLMConfig config,
  String? providerOptionsNamespace,
) {
  if (providerOptionsNamespace != null) {
    final namespaceOptions = legacyProviderOptionsNamespaceOrNull(
      config,
      providerOptionsNamespace,
    );
    final namespacedFormat = namespaceOptions?[LegacyExtensionKeys.jsonSchema];
    if (namespacedFormat is StructuredOutputFormat) {
      return namespacedFormat;
    }
  }

  return config.getExtension<StructuredOutputFormat>(
    LegacyExtensionKeys.jsonSchema,
  );
}

core.ResponseFormat? _buildCompatResponseFormat(
  StructuredOutputFormat? format,
) {
  if (format == null) {
    return null;
  }

  final schema = format.schema;
  if (schema == null) {
    throw ArgumentError.value(
      format,
      'jsonSchema',
      'Legacy jsonSchema compatibility requires an explicit schema.',
    );
  }

  return core.JsonResponseFormat(
    name: format.name,
    description: format.description,
    strict: format.strict,
    schema: core.JsonSchema.raw(
      _normalizeMap(schema),
    ),
  );
}
