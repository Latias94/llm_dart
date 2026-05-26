import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';
import '../stream/text_stream_event_provider_bridge.dart';
import 'ai_serialization_envelope_json_codec.dart';
import 'text_stream_lifecycle_event_json_codec.dart';

/// JSON codec for AI runtime full-stream events.
///
/// The wire shape remains compatible with the previous text stream envelope,
/// but event serialization is now owned by `llm_dart_ai` instead of delegating
/// through provider stream serialization.
final class TextStreamEventJsonCodec {
  static const envelopeKind = 'text-stream-events';

  const TextStreamEventJsonCodec();

  provider.JsonMap encodeEvents(List<TextStreamEvent> events) {
    return const AiSerializationEnvelopeJsonCodec().encode(
      kind: envelopeKind,
      data: {
        'events': events.map(encodeEvent).toList(growable: false),
      },
    );
  }

  List<TextStreamEvent> decodeEvents(Object? envelope) {
    final data = const AiSerializationEnvelopeJsonCodec().decode(
      envelope,
      expectedKind: envelopeKind,
    );
    return provider
        .asJsonList(data['events'], path: r'$.data.events')
        .asMap()
        .entries
        .map(
          (entry) => decodeEvent(
            entry.value,
            path: '\$.data.events[${entry.key}]',
          ),
        )
        .toList(growable: false);
  }

  provider.JsonMap encodeEvent(TextStreamEvent event) {
    return switch (event) {
      RunStartEvent() ||
      RunFinishEvent() ||
      StepStartEvent() ||
      StepFinishEvent() ||
      ToolOutputDeniedEvent() ||
      AbortEvent() =>
        const TextStreamLifecycleEventJsonCodec().encode(event),
      _ => const provider.LanguageModelStreamEventJsonCodec().encodeEvent(
          textStreamEventToProvider(event),
        ),
    };
  }

  TextStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    final map = provider.asJsonMap(value, path: path);
    final type = provider.asJsonString(map['type'], path: '$path.type');
    const lifecycleEventCodec = TextStreamLifecycleEventJsonCodec();
    if (lifecycleEventCodec.canDecode(type)) {
      return lifecycleEventCodec.decode(map, type: type, path: path);
    }

    return textStreamEventFromProvider(
      const provider.LanguageModelStreamEventJsonCodec().decodeEvent(
        map,
        path: path,
      ),
    );
  }
}
