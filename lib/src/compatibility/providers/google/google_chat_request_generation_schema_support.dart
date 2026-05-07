part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestGenerationSchemaSupport {
  final GoogleConfig config;

  const _GoogleChatRequestGenerationSchemaSupport(this.config);

  void applySchemaConfig(Map<String, dynamic> generationConfig) {
    if (config.jsonSchema != null && config.jsonSchema!.schema != null) {
      generationConfig['responseMimeType'] = 'application/json';

      final schema = Map<String, dynamic>.from(config.jsonSchema!.schema!);
      schema.remove('additionalProperties');
      generationConfig['responseSchema'] = schema;
    }
  }
}
