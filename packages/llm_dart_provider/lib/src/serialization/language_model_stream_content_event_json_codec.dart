import '../common/json_codec_common.dart';
import '../stream/language_model_stream_event.dart';
import 'serialization_media_support.dart';
import 'serialization_metadata_support.dart';

final class LanguageModelStreamContentEventJsonCodec {
  static const Set<String> eventTypes = {
    'text-start',
    'text-delta',
    'text-end',
    'reasoning-start',
    'reasoning-delta',
    'reasoning-end',
    'reasoning-file',
    'source',
    'file',
    'custom',
    'raw-chunk',
    'error',
  };

  const LanguageModelStreamContentEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  JsonMap encode(LanguageModelStreamEvent event) {
    return switch (event) {
      TextStartEvent(:final id, :final providerMetadata) => {
          'type': 'text-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextDeltaEvent(:final id, :final delta, :final providerMetadata) => {
          'type': 'text-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextEndEvent(:final id, :final providerMetadata) => {
          'type': 'text-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningStartEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningDeltaEvent(:final id, :final delta, :final providerMetadata) => {
          'type': 'reasoning-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningEndEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningFileEvent(:final file, :final providerMetadata) => {
          'type': 'reasoning-file',
          'file': SerializationMediaSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      SourceEvent(:final source) => {
          'type': 'source',
          'source': SerializationMediaSupport.encodeSourceReference(source),
        },
      FileEvent(:final file, :final providerMetadata) => {
          'type': 'file',
          'file': SerializationMediaSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      CustomEvent(:final kind, :final data, :final providerMetadata) => {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(data, path: r'$.custom.data'),
          if (providerMetadata != null)
            'providerMetadata':
                SerializationMetadataSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      RawChunkEvent(:final raw) => {
          'type': 'raw-chunk',
          'raw': ensureJsonValue(raw, path: r'$.rawChunk.raw'),
        },
      ErrorEvent(:final error) => {
          'type': 'error',
          'error': SerializationMetadataSupport.encodeModelError(error),
        },
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a provider content stream event.',
        ),
    };
  }

  LanguageModelStreamEvent decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'text-start' => TextStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-delta' => TextDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-end' => TextEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-start' => ReasoningStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-delta' => ReasoningDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-end' => ReasoningEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileEvent(
          SerializationMediaSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'source' => SourceEvent(
          SerializationMediaSupport.decodeSourceReference(
            map['source'],
            path: '$path.source',
          ),
        ),
      'file' => FileEvent(
          SerializationMediaSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomEvent(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: SerializationMetadataSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'raw-chunk' => RawChunkEvent(map['raw']),
      'error' => ErrorEvent(
          SerializationMetadataSupport.decodeModelError(
            _requireValue(map['error'], path: '$path.error'),
            path: '$path.error',
          ),
        ),
      _ => throw FormatException(
          'Unsupported provider content stream event type "$type" at $path.',
        ),
    };
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
}
