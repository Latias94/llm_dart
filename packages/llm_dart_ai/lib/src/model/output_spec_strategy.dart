import 'dart:async';

import '../common/partial_json.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_foundation.dart';
import 'output_spec_json.dart';

abstract class OutputSpec<T> {
  const OutputSpec();

  ResponseFormat? get responseFormat;

  FutureOr<T> parse({
    required String text,
    required StructuredOutputContext context,
  });

  FutureOr<Object?> parsePartial({
    required String text,
  }) {
    return null;
  }

  Iterable<OutputStreamEvent<T>> createElementEvents({
    required Object partialOutput,
    required Object? previousPartialOutput,
  }) sync* {}
}

final class TextOutputSpec extends OutputSpec<String> {
  const TextOutputSpec();

  @override
  ResponseFormat get responseFormat => const TextResponseFormat();

  @override
  String parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    return text;
  }

  @override
  String parsePartial({
    required String text,
  }) {
    return text;
  }
}

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
