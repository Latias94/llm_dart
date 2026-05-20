import '../language/openai_response_format.dart';

Map<String, Object?> encodeOpenAIJsonSchemaResponseFormat(
  OpenAIJsonSchemaResponseFormat responseFormat,
) {
  return {
    'type': 'json_schema',
    'json_schema': {
      'name': responseFormat.name,
      if (responseFormat.description != null)
        'description': responseFormat.description,
      if (responseFormat.schema != null)
        'schema': ensureOpenAIJsonSchemaObject(responseFormat.schema!),
      if (responseFormat.strict != null) 'strict': responseFormat.strict,
    },
  };
}

Map<String, Object?> ensureOpenAIJsonSchemaObject(
  Map<String, Object?> schema,
) {
  final normalized = Map<String, Object?>.from(schema);
  if (!normalized.containsKey('additionalProperties')) {
    normalized['additionalProperties'] = false;
  }
  return normalized;
}
