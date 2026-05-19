import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';

final class TextStreamContentEventJsonCodec {
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

  const TextStreamContentEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  provider.JsonMap encode(TextStreamEvent event) {
    return switch (event) {
      TextStartEvent(:final id, :final providerMetadata) => {
          'type': 'text-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextDeltaEvent(:final id, :final delta, :final providerMetadata) => {
          'type': 'text-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextEndEvent(:final id, :final providerMetadata) => {
          'type': 'text-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningStartEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningDeltaEvent(
        :final id,
        :final delta,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningEndEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningFileEvent(:final file, :final providerMetadata) => {
          'type': 'reasoning-file',
          'file': provider.SerializationJsonSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      SourceEvent(:final source) => {
          'type': 'source',
          'source': provider.SerializationJsonSupport.encodeSourceReference(
            source,
          ),
        },
      FileEvent(:final file, :final providerMetadata) => {
          'type': 'file',
          'file': provider.SerializationJsonSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      CustomEvent(:final kind, :final data, :final providerMetadata) => {
          'type': 'custom',
          'kind': kind,
          'data': provider.ensureJsonValue(data, path: r'$.custom.data'),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      RawChunkEvent(:final raw) => {
          'type': 'raw-chunk',
          'raw': provider.ensureJsonValue(raw, path: r'$.rawChunk.raw'),
        },
      ErrorEvent(:final error) => {
          'type': 'error',
          'error': provider.SerializationJsonSupport.encodeModelError(error),
        },
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a content text stream event.',
        ),
    };
  }

  TextStreamEvent decode(
    provider.JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'text-start' => TextStartEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-delta' => TextDeltaEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          delta: provider.asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-end' => TextEndEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-start' => ReasoningStartEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-delta' => ReasoningDeltaEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          delta: provider.asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-end' => ReasoningEndEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileEvent(
          provider.SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'source' => SourceEvent(
          provider.SerializationJsonSupport.decodeSourceReference(
            map['source'],
            path: '$path.source',
          ),
        ),
      'file' => FileEvent(
          provider.SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomEvent(
          kind: provider.asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'raw-chunk' => RawChunkEvent(map['raw']),
      'error' => ErrorEvent(
          provider.SerializationJsonSupport.decodeModelError(
            _requireValue(map['error'], path: '$path.error'),
            path: '$path.error',
          ),
        ),
      _ => throw FormatException(
          'Unsupported content text stream event type "$type" at $path.',
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
