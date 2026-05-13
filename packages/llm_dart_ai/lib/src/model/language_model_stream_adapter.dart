import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';
import '../stream/text_stream_event_provider_bridge.dart';

/// Adapts provider-owned model-call events into the runtime text stream shape.
///
/// Keeping this adapter in `llm_dart_ai` establishes the ownership seam:
/// provider streams are validated as model-call events before the runtime
/// treats them as [TextStreamEvent] values.
Stream<TextStreamEvent> adaptLanguageModelStreamEvents(
  Stream<provider.LanguageModelStreamEvent> events, {
  String context = 'LanguageModelStreamEvent',
}) async* {
  await for (final event in events) {
    yield languageModelStreamEventToTextStreamEvent(
      event,
      context: context,
    );
  }
}
