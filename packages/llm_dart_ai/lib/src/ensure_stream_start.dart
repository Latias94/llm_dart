import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Ensure a stream starts with exactly one [LLMStreamStartPart].
///
/// - If the upstream stream already starts with [LLMStreamStartPart], it is
///   forwarded (optionally merged with [warnings]).
/// - Otherwise, a new [LLMStreamStartPart] is injected before the first part.
Stream<LLMStreamPart> ensureStreamStartPart(
  Stream<LLMStreamPart> upstream, {
  List<LLMWarning> warnings = const [],
}) async* {
  final iterator = StreamIterator(upstream);
  try {
    if (!await iterator.moveNext()) {
      yield LLMStreamStartPart(warnings: warnings);
      return;
    }

    final first = iterator.current;
    if (first is LLMStreamStartPart) {
      if (warnings.isEmpty) {
        yield first;
      } else {
        yield LLMStreamStartPart(warnings: [...warnings, ...first.warnings]);
      }
    } else {
      yield LLMStreamStartPart(warnings: warnings);
      yield first;
    }

    while (await iterator.moveNext()) {
      yield iterator.current;
    }
  } finally {
    await iterator.cancel();
  }
}
