import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_response_format.dart';

OpenAIJsonSchemaResponseFormat? resolveOpenAIFamilySharedResponseFormat(
  ResponseFormat? responseFormat,
) {
  return switch (responseFormat) {
    null || TextResponseFormat() => null,
    JsonResponseFormat(
      schema: final schema,
      name: final name,
      description: final description,
      strict: final strict,
    ) =>
      OpenAIJsonSchemaResponseFormat(
        name: name ?? 'structured_output',
        description: description,
        schema: schema.toJson(),
        strict: strict,
      ),
  };
}
