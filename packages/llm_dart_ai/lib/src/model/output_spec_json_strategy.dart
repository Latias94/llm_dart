import '../common/partial_json.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_base.dart';
import 'output_spec_foundation.dart';
import 'output_spec_json.dart';

final class JsonOutputSpec<T> extends OutputSpec<T> {
  final JsonSchema schema;
  final String? name;
  final String? description;
  final JsonOutputDecoder<T> decode;

  const JsonOutputSpec({
    required this.schema,
    required this.decode,
    this.name,
    this.description,
  });

  static JsonOutputSpec<Object?> json({
    required JsonSchema schema,
    String? name,
    String? description,
  }) {
    return JsonOutputSpec<Object?>(
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
    return decode(json);
  }

  @override
  Object? parsePartial({
    required String text,
  }) {
    final result = parsePartialJson(text);
    return switch (result.state) {
      PartialJsonParseState.undefinedInput ||
      PartialJsonParseState.failedParse =>
        null,
      PartialJsonParseState.successfulParse ||
      PartialJsonParseState.repairedParse =>
        freezeStructuredOutputJsonValue(result.value),
    };
  }
}
