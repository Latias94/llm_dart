import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_foundation.dart';

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
