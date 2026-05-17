import '../common/partial_json.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_base.dart';
import 'output_spec_foundation.dart';
import 'output_spec_json.dart';

final class ArrayOutputSpec<T> extends OutputSpec<List<T>> {
  final JsonSchema elementSchema;
  final String? name;
  final String? description;
  final JsonArrayElementDecoder<T> decodeElement;

  const ArrayOutputSpec({
    required this.elementSchema,
    required this.decodeElement,
    this.name,
    this.description,
  });

  static ArrayOutputSpec<Object?> json({
    required JsonSchema elementSchema,
    String? name,
    String? description,
  }) {
    return ArrayOutputSpec<Object?>(
      elementSchema: elementSchema,
      name: name,
      description: description,
      decodeElement: (json) => json,
    );
  }

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: JsonSchema.object(
          properties: {
            'elements': JsonSchema.array(
              items: elementSchema.toJson(),
            ).toJson(),
          },
          required: const ['elements'],
          additionalProperties: false,
        ),
        name: name,
        description: description,
      );

  @override
  List<T> parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    final json = decodeStructuredOutputJsonText(text);
    final object = requireStructuredOutputJsonObject(
      json,
      message:
          'Could not parse structured output array: expected an object with an "elements" array.',
    );
    final rawElements = object['elements'];
    if (rawElements is! List) {
      throw const FormatException(
        'Could not parse structured output array: expected an "elements" array.',
      );
    }

    return List<T>.unmodifiable(
      rawElements.map(decodeElement),
    );
  }

  @override
  List<T>? parsePartial({
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
        final rawElements = object?['elements'];
        if (rawElements is! List) {
          return null;
        }

        final candidateElements =
            result.state == PartialJsonParseState.repairedParse &&
                    rawElements.isNotEmpty
                ? rawElements.take(rawElements.length - 1)
                : rawElements;

        final parsedElements = <T>[];
        for (final rawElement in candidateElements) {
          try {
            parsedElements.add(decodeElement(rawElement));
          } catch (_) {
            continue;
          }
        }

        return List<T>.unmodifiable(parsedElements);
    }
  }

  @override
  Iterable<OutputStreamEvent<List<T>>> createElementEvents({
    required Object partialOutput,
    required Object? previousPartialOutput,
  }) sync* {
    final partial = partialOutput as List<T>;
    final previous = previousPartialOutput as List<T>?;
    final previousLength = previous?.length ?? 0;

    if (partial.length < previousLength) {
      return;
    }

    for (var index = previousLength; index < partial.length; index++) {
      yield OutputElementEvent<T>(partial[index]);
    }
  }
}
