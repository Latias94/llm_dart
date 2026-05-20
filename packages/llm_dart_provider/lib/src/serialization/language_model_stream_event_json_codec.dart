import '../common/json_codec_common.dart';
import '../stream/language_model_stream_event.dart';
import 'language_model_stream_content_event_json_codec.dart';
import 'language_model_stream_core_event_json_codec.dart';
import 'language_model_stream_tool_event_json_codec.dart';
import 'serialization_protocol.dart';

/// JSON codec for provider-owned language model stream events.
///
/// The wire shape intentionally stays compatible with the legacy text stream
/// envelope, but this codec owns only model-call event types. Runtime lifecycle
/// events belong to the AI runtime serialization layer and are rejected here.
final class LanguageModelStreamEventJsonCodec {
  static const envelopeKind = 'text-stream-events';

  const LanguageModelStreamEventJsonCodec();

  JsonMap encodeEvents(List<LanguageModelStreamEvent> events) {
    _validateEvents(
      events,
      operation: 'LanguageModelStreamEventJsonCodec.encodeEvents',
    );
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'events': events.map(encodeEvent).toList(growable: false),
      },
    };
  }

  List<LanguageModelStreamEvent> decodeEvents(Object? envelope) {
    final root = asJsonMap(envelope, path: r'$');
    final kind = asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = asJsonMap(root['data'], path: r'$.data');
    return asJsonList(data['events'], path: r'$.data.events')
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

  JsonMap encodeEvent(LanguageModelStreamEvent event) {
    validateLanguageModelStreamEvent(
      event,
      context: 'LanguageModelStreamEventJsonCodec.encodeEvent',
    );

    return switch (event) {
      StartEvent() ||
      ResponseMetadataEvent() ||
      FinishEvent() =>
        const LanguageModelStreamCoreEventJsonCodec().encode(event),
      TextStartEvent() ||
      TextDeltaEvent() ||
      TextEndEvent() ||
      ReasoningStartEvent() ||
      ReasoningDeltaEvent() ||
      ReasoningEndEvent() ||
      ReasoningFileEvent() =>
        const LanguageModelStreamContentEventJsonCodec().encode(event),
      ToolInputStartEvent() ||
      ToolInputDeltaEvent() ||
      ToolInputEndEvent() ||
      ToolInputErrorEvent() ||
      ToolCallEvent() ||
      ToolResultEvent() ||
      ToolApprovalRequestEvent() =>
        const LanguageModelStreamToolEventJsonCodec().encode(event),
      SourceEvent() ||
      FileEvent() =>
        const LanguageModelStreamContentEventJsonCodec().encode(event),
      CustomEvent() ||
      RawChunkEvent() ||
      ErrorEvent() =>
        const LanguageModelStreamContentEventJsonCodec().encode(event),
    };
  }

  LanguageModelStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');
    const toolEventCodec = LanguageModelStreamToolEventJsonCodec();
    if (toolEventCodec.canDecode(type)) {
      return toolEventCodec.decode(map, type: type, path: path);
    }
    const contentEventCodec = LanguageModelStreamContentEventJsonCodec();
    if (contentEventCodec.canDecode(type)) {
      return contentEventCodec.decode(map, type: type, path: path);
    }
    const coreEventCodec = LanguageModelStreamCoreEventJsonCodec();
    if (coreEventCodec.canDecode(type) || coreEventCodec.canReject(type)) {
      return coreEventCodec.decode(map, type: type, path: path);
    }

    throw FormatException(
      'Unsupported language model stream event type "$type" at $path.',
    );
  }

  void _validateEvents(
    Iterable<LanguageModelStreamEvent> events, {
    required String operation,
  }) {
    var index = 0;
    for (final event in events) {
      validateLanguageModelStreamEvent(
        event,
        context: '$operation event[$index]',
      );
      index += 1;
    }
  }
}
