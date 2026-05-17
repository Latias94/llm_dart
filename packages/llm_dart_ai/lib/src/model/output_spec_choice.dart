import '../common/partial_json.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_base.dart';
import 'output_spec_foundation.dart';
import 'output_spec_json.dart';

final class ChoiceOutputSpec<T extends String> extends OutputSpec<T> {
  final List<T> options;
  final String? name;
  final String? description;

  ChoiceOutputSpec({
    required List<T> options,
    this.name,
    this.description,
  }) : options = normalizeStructuredOutputChoiceOptions(options);

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: JsonSchema.object(
          properties: {
            'result': JsonSchema.string(
              enumValues: options,
            ).toJson(),
          },
          required: const ['result'],
          additionalProperties: false,
        ),
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
          'Could not parse structured output choice: expected an object with a "result" field.',
    );
    final value = object['result'];
    if (value is! String) {
      throw const FormatException(
        'Could not parse structured output choice: expected a string "result" value.',
      );
    }

    for (final option in options) {
      if (option == value) {
        return option;
      }
    }

    throw FormatException(
      'Could not parse structured output choice: expected one of ${options.join(', ')}.',
    );
  }

  @override
  T? parsePartial({
    required String text,
  }) {
    final result = parsePartialJson(text);
    switch (result.state) {
      case PartialJsonParseState.undefinedInput ||
            PartialJsonParseState.failedParse:
        return null;
      case PartialJsonParseState.successfulParse ||
            PartialJsonParseState.repairedParse:
        final object = tryRequireStructuredOutputJsonObject(result.value);
        final value = object?['result'];
        if (value is! String) {
          return null;
        }

        final potentialMatches = options
            .where((option) => option.startsWith(value))
            .toList(growable: false);

        if (result.state == PartialJsonParseState.successfulParse) {
          return potentialMatches.contains(value)
              ? potentialMatches.firstWhere((option) => option == value)
              : null;
        }

        return potentialMatches.length == 1 ? potentialMatches.single : null;
    }
  }
}
