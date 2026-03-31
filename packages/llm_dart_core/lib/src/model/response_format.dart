import '../common/json_schema.dart';

sealed class ResponseFormat {
  const ResponseFormat();
}

final class TextResponseFormat extends ResponseFormat {
  const TextResponseFormat();
}

final class JsonResponseFormat extends ResponseFormat {
  final JsonSchema schema;
  final String? name;
  final String? description;
  final bool? strict;

  const JsonResponseFormat({
    required this.schema,
    this.name,
    this.description,
    this.strict,
  });
}
