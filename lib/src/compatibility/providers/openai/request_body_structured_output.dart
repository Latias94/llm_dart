part of 'request_body_support.dart';

const _structuredOutputCodec = OpenAIStructuredOutputCodec();

/// Builds the OpenAI structured-output request shape while preserving the
/// compatibility rule that `additionalProperties` defaults to `false`.
Map<String, dynamic> buildOpenAICompatStructuredOutputFormat(
  StructuredOutputFormat schema,
) {
  return _structuredOutputCodec.toJson(schema);
}
