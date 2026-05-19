import 'openai_json_value.dart';
import 'openai_response_format.dart';

final class OpenAIAssistantResponseFormat {
  final String type;
  final OpenAIJsonSchemaResponseFormat? jsonSchema;
  final Map<String, Object?> extra;

  const OpenAIAssistantResponseFormat({
    required this.type,
    this.jsonSchema,
    this.extra = const {},
  });

  const OpenAIAssistantResponseFormat.text()
      : type = 'text',
        jsonSchema = null,
        extra = const {};

  const OpenAIAssistantResponseFormat.jsonObject()
      : type = 'json_object',
        jsonSchema = null,
        extra = const {};

  const OpenAIAssistantResponseFormat.jsonSchema(
    this.jsonSchema, {
    this.extra = const {},
  }) : type = 'json_schema';

  factory OpenAIAssistantResponseFormat.fromJson(Map<String, Object?> json) {
    final type = openAIRequiredNonEmptyString(
      json['type'],
      path: 'assistant.response_format.type',
    );
    final rawJsonSchema = json['json_schema'];
    return OpenAIAssistantResponseFormat(
      type: type,
      jsonSchema: rawJsonSchema == null
          ? null
          : openAIJsonSchemaResponseFormatFromJson(
              openAIRequiredMap(
                rawJsonSchema,
                path: 'assistant.response_format.json_schema',
              ),
            ),
      extra: Map.unmodifiable(
        Map<String, Object?>.from(json)
          ..remove('type')
          ..remove('json_schema'),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'type': type,
      if (jsonSchema != null) 'json_schema': jsonSchema!.toJsonSchema(),
      ...extra,
    };
  }
}

OpenAIJsonSchemaResponseFormat openAIJsonSchemaResponseFormatFromJson(
  Map<String, Object?> json,
) {
  return OpenAIJsonSchemaResponseFormat(
    name: openAIRequiredNonEmptyString(json['name'], path: 'json_schema.name'),
    description: openAIOptionalString(
      json['description'],
      path: 'json_schema.description',
    ),
    schema: json['schema'] == null
        ? null
        : openAIRequiredMap(json['schema'], path: 'json_schema.schema'),
    strict: openAIOptionalBool(json['strict'], path: 'json_schema.strict'),
  );
}
