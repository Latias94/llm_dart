import '../common/json_codec_common.dart';
import '../model/finish_reason.dart';
import '../model/model_response_metadata.dart';
import '../stream/language_model_stream_event.dart';
import 'language_model_stream_tool_event_json_codec.dart';
import 'serialization_json_support.dart';
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
      StartEvent(:final warnings) => {
          'type': 'start',
          'warnings': warnings
              .map(SerializationJsonSupport.encodeModelWarning)
              .toList(growable: false),
        },
      ResponseMetadataEvent(
        :final responseMetadata,
        :final responseId,
        :final timestamp,
        :final modelId,
        :final providerMetadata,
      ) =>
        {
          'type': 'response-metadata',
          ...SerializationJsonSupport.encodeModelResponseMetadata(
            modelResponseMetadataFrom(
                  metadata: responseMetadata,
                  id: responseId,
                  timestamp: timestamp,
                  modelId: modelId,
                ) ??
                const ModelResponseMetadata(),
          ),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextStartEvent(:final id, :final providerMetadata) => {
          'type': 'text-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextDeltaEvent(:final id, :final delta, :final providerMetadata) => {
          'type': 'text-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextEndEvent(:final id, :final providerMetadata) => {
          'type': 'text-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningStartEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningDeltaEvent(:final id, :final delta, :final providerMetadata) => {
          'type': 'reasoning-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningEndEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningFileEvent(:final file, :final providerMetadata) => {
          'type': 'reasoning-file',
          'file': SerializationJsonSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolInputStartEvent() ||
      ToolInputDeltaEvent() ||
      ToolInputEndEvent() ||
      ToolInputErrorEvent() ||
      ToolCallEvent() ||
      ToolResultEvent() ||
      ToolApprovalRequestEvent() =>
        const LanguageModelStreamToolEventJsonCodec().encode(event),
      SourceEvent(:final source) => {
          'type': 'source',
          'source': SerializationJsonSupport.encodeSourceReference(source),
        },
      FileEvent(:final file, :final providerMetadata) => {
          'type': 'file',
          'file': SerializationJsonSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      FinishEvent(
        :final finishReason,
        :final rawFinishReason,
        :final usage,
        :final providerMetadata,
      ) =>
        {
          'type': 'finish',
          'finishReason': finishReason.name,
          if (rawFinishReason != null) 'rawFinishReason': rawFinishReason,
          if (usage != null)
            'usage': SerializationJsonSupport.encodeUsageStats(usage),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      CustomEvent(:final kind, :final data, :final providerMetadata) => {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(data, path: r'$.custom.data'),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      RawChunkEvent(:final raw) => {
          'type': 'raw-chunk',
          'raw': ensureJsonValue(raw, path: r'$.rawChunk.raw'),
        },
      ErrorEvent(:final error) => {
          'type': 'error',
          'error': SerializationJsonSupport.encodeModelError(error),
        },
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

    return switch (type) {
      'start' => StartEvent(
          warnings: asJsonList(map['warnings'], path: '$path.warnings')
              .asMap()
              .entries
              .map(
                (entry) => SerializationJsonSupport.decodeModelWarning(
                  entry.value,
                  path: '$path.warnings[${entry.key}]',
                ),
              )
              .toList(growable: false),
        ),
      'response-metadata' => ResponseMetadataEvent(
          responseMetadata:
              SerializationJsonSupport.decodeModelResponseMetadataFields(
            map,
            path: path,
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-start' => TextStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-delta' => TextDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-end' => TextEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-start' => ReasoningStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-delta' => ReasoningDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-end' => ReasoningEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileEvent(
          SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-output-denied' ||
      'step-start' ||
      'step-end' ||
      'step-finish' ||
      'abort' =>
        _throwRuntimeOnlyType(type, path: path),
      'source' => SourceEvent(
          SerializationJsonSupport.decodeSourceReference(
            map['source'],
            path: '$path.source',
          ),
        ),
      'file' => FileEvent(
          SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'finish' => FinishEvent(
          finishReason: FinishReason.values.byName(
            asJsonString(map['finishReason'], path: '$path.finishReason'),
          ),
          rawFinishReason: asNullableJsonString(
            map['rawFinishReason'],
            path: '$path.rawFinishReason',
          ),
          usage: SerializationJsonSupport.decodeUsageStats(
            map['usage'],
            path: '$path.usage',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomEvent(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'raw-chunk' => RawChunkEvent(map['raw']),
      'error' => ErrorEvent(
          SerializationJsonSupport.decodeModelError(
            _requireValue(map['error'], path: '$path.error'),
            path: '$path.error',
          ),
        ),
      _ => throw FormatException(
          'Unsupported language model stream event type "$type" at $path.',
        ),
    };
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

  Object _requireValue(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      throw FormatException('Expected non-null value at $path.');
    }

    return value;
  }

  Never _throwRuntimeOnlyType(
    String type, {
    required String path,
  }) {
    throw StateError(
      'LanguageModelStreamEventJsonCodec cannot decode runtime-only event type '
      '"$type" at $path. Provider stream serialization may decode only '
      'model-call events.',
    );
  }
}
