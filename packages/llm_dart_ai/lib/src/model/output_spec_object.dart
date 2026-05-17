import '../common/partial_json.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_base.dart';
import 'output_spec_foundation.dart';
import 'output_spec_json.dart';

final class ObjectOutputSpec<T> extends OutputSpec<T> {
  final JsonSchema schema;
  final String? name;
  final String? description;
  final JsonObjectDecoder<T> decode;

  ObjectOutputSpec({
    required JsonSchema schema,
    required this.decode,
    this.name,
    this.description,
  }) : schema = validateStructuredOutputObjectSchema(schema);

  static ObjectOutputSpec<Map<String, Object?>> json({
    required JsonSchema schema,
    String? name,
    String? description,
  }) {
    return ObjectOutputSpec<Map<String, Object?>>(
      schema: schema,
      name: name,
      description: description,
      decode: (json) => json,
    );
  }

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: schema,
        name: name,
        description: description,
      );

  @override
  T parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    final json = decodeStructuredOutputJsonText(text);
    final object = requireStructuredOutputJsonObject(
      json,
      message:
          'Could not parse structured output object: expected a JSON object root.',
    );
    return decode(object);
  }

  @override
  Map<String, Object?>? parsePartial({
    required String text,
  }) {
    final result = parsePartialJson(text);
    return switch (result.state) {
      PartialJsonParseState.undefinedInput ||
      PartialJsonParseState.failedParse =>
        null,
      PartialJsonParseState.successfulParse ||
      PartialJsonParseState.repairedParse =>
        tryRequireStructuredOutputJsonObject(result.value),
    };
  }
}
