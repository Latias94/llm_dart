final class OpenAIJsonSchemaResponseFormat {
  final String name;
  final String? description;
  final Map<String, Object?>? schema;
  final bool? strict;

  const OpenAIJsonSchemaResponseFormat({
    required this.name,
    this.description,
    this.schema,
    this.strict,
  });

  Map<String, Object?> toJsonSchema() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (schema != null) 'schema': schema,
      if (strict != null) 'strict': strict,
    };
  }
}
