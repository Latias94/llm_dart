import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';
import 'text_stream_content_event_json_codec.dart';
import 'text_stream_lifecycle_event_json_codec.dart';
import 'text_stream_tool_event_json_codec.dart';

/// JSON codec for AI runtime full-stream events.
///
/// The wire shape remains compatible with the previous text stream envelope,
/// but event serialization is now owned by `llm_dart_ai` instead of delegating
/// through provider stream serialization.
final class TextStreamEventJsonCodec {
  static const envelopeKind = 'text-stream-events';

  const TextStreamEventJsonCodec();

  provider.JsonMap encodeEvents(List<TextStreamEvent> events) {
    return {
      'schemaVersion': provider.llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'events': events.map(encodeEvent).toList(growable: false),
      },
    };
  }

  List<TextStreamEvent> decodeEvents(Object? envelope) {
    final root = provider.asJsonMap(envelope, path: r'$');
    final kind = provider.asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = provider.asJsonMap(root['data'], path: r'$.data');
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
      StartEvent() ||
      ResponseMetadataEvent() ||
      StepStartEvent() ||
      StepFinishEvent() ||
      FinishEvent() ||
      AbortEvent() =>
        const TextStreamLifecycleEventJsonCodec().encode(event),
      TextStartEvent() ||
      TextDeltaEvent() ||
      TextEndEvent() ||
      ReasoningStartEvent() ||
      ReasoningDeltaEvent() ||
      ReasoningEndEvent() ||
      ReasoningFileEvent() =>
        const TextStreamContentEventJsonCodec().encode(event),
      ToolInputStartEvent() ||
      ToolInputDeltaEvent() ||
      ToolInputEndEvent() ||
      ToolInputErrorEvent() ||
      ToolCallEvent() ||
      ToolResultEvent() ||
      ToolApprovalRequestEvent() ||
      ToolOutputDeniedEvent() =>
        const TextStreamToolEventJsonCodec().encode(event),
      SourceEvent() ||
      FileEvent() =>
        const TextStreamContentEventJsonCodec().encode(event),
      CustomEvent() ||
      RawChunkEvent() ||
      ErrorEvent() =>
        const TextStreamContentEventJsonCodec().encode(event),
    };
  }

  TextStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    final map = provider.asJsonMap(value, path: path);
    final type = provider.asJsonString(map['type'], path: '$path.type');
    const toolEventCodec = TextStreamToolEventJsonCodec();
    if (toolEventCodec.canDecode(type)) {
      return toolEventCodec.decode(map, type: type, path: path);
    }
    const contentEventCodec = TextStreamContentEventJsonCodec();
    if (contentEventCodec.canDecode(type)) {
      return contentEventCodec.decode(map, type: type, path: path);
    }
    const lifecycleEventCodec = TextStreamLifecycleEventJsonCodec();
    if (lifecycleEventCodec.canDecode(type)) {
      return lifecycleEventCodec.decode(map, type: type, path: path);
    }

    throw FormatException(
      'Unsupported text stream event type "$type" at $path.',
    );
  }
}
