import '../../../../models/tool_models.dart';

/// OpenAI-compatible structured output codec for request payloads.
final class OpenAIStructuredOutputCodec {
  const OpenAIStructuredOutputCodec();

  Map<String, dynamic> toJson(StructuredOutputFormat schema) {
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
}
