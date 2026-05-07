part of 'legacy_chat_adapter.dart';

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
