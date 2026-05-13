import 'dart:async';

import 'text_stream_event.dart';

/// Provider-owned name for events emitted by a single language model call.
///
/// Provider-facing code should use [LanguageModelStreamEvent] and validate
/// events with [validateLanguageModelStreamEvent] so runtime-only events do not
/// leak back into provider contracts.
typedef LanguageModelStreamEvent = TextStreamEvent;

bool isLanguageModelStreamEvent(LanguageModelStreamEvent event) {
  return switch (event) {
    StepStartEvent() ||
    StepFinishEvent() ||
    ToolOutputDeniedEvent() ||
    AbortEvent() =>
      false,
    _ => true,
  };
}

void validateLanguageModelStreamEvent(
  LanguageModelStreamEvent event, {
  String context = 'LanguageModelStreamEvent',
}) {
  if (isLanguageModelStreamEvent(event)) {
    return;
  }

  throw StateError(
    '$context cannot contain runtime-only event ${event.runtimeType}. '
    'Provider streams may emit only model-call events.',
  );
}

Stream<LanguageModelStreamEvent> validateLanguageModelStreamEvents(
  Stream<LanguageModelStreamEvent> events, {
  String context = 'LanguageModelStreamEvent',
}) async* {
  await for (final event in events) {
    validateLanguageModelStreamEvent(event, context: context);
    yield event;
  }
}
