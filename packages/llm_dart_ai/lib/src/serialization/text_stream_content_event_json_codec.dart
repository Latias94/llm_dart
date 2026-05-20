import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';
import 'text_stream_text_content_event_json_codec.dart';

final class TextStreamContentEventJsonCodec {
  static const Set<String> eventTypes = {
    ...TextStreamTextContentEventJsonCodec.eventTypes,
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
      TextStartEvent() ||
      TextDeltaEvent() ||
      TextEndEvent() ||
      ReasoningStartEvent() ||
      ReasoningDeltaEvent() ||
      ReasoningEndEvent() ||
      ReasoningFileEvent() =>
        const TextStreamTextContentEventJsonCodec().encode(event),
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
    const textContentCodec = TextStreamTextContentEventJsonCodec();
    if (textContentCodec.canDecode(type)) {
      return textContentCodec.decode(map, type: type, path: path);
    }

    return switch (type) {
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
