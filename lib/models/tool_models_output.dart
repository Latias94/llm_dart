/// Defines a JSON schema-backed structured output contract.
class StructuredOutputFormat {
  /// Name of the schema
  final String name;

  /// The description of the schema
  final String? description;

  /// The JSON schema for the structured output
  final Map<String, dynamic>? schema;

  /// Whether to enable strict schema adherence
  final bool? strict;

  const StructuredOutputFormat({
    required this.name,
    this.description,
    this.schema,
    this.strict,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};

    if (description != null) {
      json['description'] = description;
    }

    if (schema != null) {
      json['schema'] = schema;
    }

    if (strict != null) {
      json['strict'] = strict;
    }

    return json;
  }

  factory StructuredOutputFormat.fromJson(Map<String, dynamic> json) =>
      StructuredOutputFormat(
        name: json['name'] as String,
        description: json['description'] as String?,
        schema: json['schema'] as Map<String, dynamic>?,
        strict: json['strict'] as bool?,
      );
}
