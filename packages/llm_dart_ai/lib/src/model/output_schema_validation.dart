import 'package:llm_dart_provider/llm_dart_provider.dart';

JsonSchema validateStructuredOutputObjectSchema(JsonSchema schema) {
  final type = schema.toJson()['type'];
  if (type != 'object') {
    throw ArgumentError.value(
      schema,
      'schema',
      'ObjectOutputSpec requires an object-rooted schema.',
    );
  }

  return schema;
}

List<T> normalizeStructuredOutputChoiceOptions<T extends String>(
  List<T> options,
) {
  if (options.isEmpty) {
    throw ArgumentError.value(
      options,
      'options',
      'ChoiceOutputSpec requires at least one option.',
    );
  }

  final seen = <String>{};
  final normalized = <T>[];
  for (final option in options) {
    if (option.isEmpty) {
      throw ArgumentError.value(
        option,
        'options',
        'ChoiceOutputSpec options must not be empty.',
      );
    }

    if (!seen.add(option)) {
      throw ArgumentError.value(
        option,
        'options',
        'ChoiceOutputSpec options must be unique.',
      );
    }

    normalized.add(option);
  }

  return List<T>.unmodifiable(normalized);
}
