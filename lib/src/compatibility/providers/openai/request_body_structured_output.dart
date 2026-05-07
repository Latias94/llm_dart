part of 'request_body_support.dart';

/// Builds the OpenAI structured-output request shape while preserving the
/// compatibility rule that `additionalProperties` defaults to `false`.
Map<String, dynamic> buildOpenAICompatStructuredOutputFormat(
  StructuredOutputFormat schema,
) {
  final responseFormat = <String, dynamic>{
    'type': 'json_schema',
    'json_schema': schema.toJson(),
  };

  if (schema.schema != null) {
    final schemaMap = Map<String, dynamic>.from(schema.schema!);
    if (!schemaMap.containsKey('additionalProperties')) {
      schemaMap['additionalProperties'] = false;
    }

    responseFormat['json_schema'] = {
      'name': schema.name,
      if (schema.description != null) 'description': schema.description,
      'schema': schemaMap,
      if (schema.strict != null) 'strict': schema.strict,
    };
  }

  return responseFormat;
}
