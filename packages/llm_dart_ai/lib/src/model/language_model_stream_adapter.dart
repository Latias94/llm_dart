import 'package:llm_dart_provider/llm_dart_provider.dart';

/// Adapts provider-owned model-call events into the runtime text stream shape.
///
/// The current implementation is intentionally small because
/// [LanguageModelStreamEvent] is still a compatibility typedef during the
/// boundary migration. Keeping the adapter in `llm_dart_ai` establishes the
/// ownership seam: provider streams are validated as model-call events before
/// the runtime treats them as [TextStreamEvent] values.
Stream<TextStreamEvent> adaptLanguageModelStreamEvents(
  Stream<LanguageModelStreamEvent> events, {
  String context = 'LanguageModelStreamEvent',
}) async* {
  await for (final event in events) {
    validateLanguageModelStreamEvent(event, context: context);
    yield event;
  }
}
