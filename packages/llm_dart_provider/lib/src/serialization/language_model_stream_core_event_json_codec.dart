import '../common/json_codec_common.dart';
import '../model/finish_reason.dart';
import '../model/model_response_metadata.dart';
import '../stream/language_model_stream_event.dart';
import 'serialization_metadata_support.dart';

final class LanguageModelStreamCoreEventJsonCodec {
  static const Set<String> eventTypes = {
    'start',
    'response-metadata',
    'finish',
  };

  static const Set<String> runtimeOnlyEventTypes = {
    'tool-output-denied',
    'step-start',
    'step-end',
    'step-finish',
    'abort',
  };

  const LanguageModelStreamCoreEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  bool canReject(String type) => runtimeOnlyEventTypes.contains(type);

  JsonMap encode(LanguageModelStreamEvent event) {
    return switch (event) {
      StartEvent(:final warnings) => {
          'type': 'start',
          'warnings': warnings
              .map(SerializationMetadataSupport.encodeModelWarning)
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
          ...SerializationMetadataSupport.encodeModelResponseMetadata(
            modelResponseMetadataFrom(
                  metadata: responseMetadata,
                  id: responseId,
                  timestamp: timestamp,
                  modelId: modelId,
                ) ??
                const ModelResponseMetadata(),
          ),
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
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
            'usage': SerializationMetadataSupport.encodeUsageStats(usage),
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a provider core stream event.',
        ),
    };
  }

  LanguageModelStreamEvent decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'start' => StartEvent(
          warnings: asJsonList(map['warnings'], path: '$path.warnings')
              .asMap()
              .entries
              .map(
                (entry) => SerializationMetadataSupport.decodeModelWarning(
                  entry.value,
                  path: '$path.warnings[${entry.key}]',
                ),
              )
              .toList(growable: false),
        ),
      'response-metadata' => ResponseMetadataEvent(
          responseMetadata:
              SerializationMetadataSupport.decodeModelResponseMetadataFields(
            map,
            path: path,
          ),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
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
          usage: SerializationMetadataSupport.decodeUsageStats(
            map['usage'],
            path: '$path.usage',
          ),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      _ when runtimeOnlyEventTypes.contains(type) =>
        _throwRuntimeOnlyType(type, path: path),
      _ => throw FormatException(
          'Unsupported provider core stream event type "$type" at $path.',
        ),
    };
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
