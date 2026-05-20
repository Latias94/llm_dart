import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';

final class TextStreamTextContentEventJsonCodec {
  static const Set<String> eventTypes = {
    'text-start',
    'text-delta',
    'text-end',
    'reasoning-start',
    'reasoning-delta',
    'reasoning-end',
    'reasoning-file',
  };

  const TextStreamTextContentEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  provider.JsonMap encode(TextStreamEvent event) {
    return switch (event) {
      TextStartEvent(:final id, :final providerMetadata) => {
          'type': 'text-start',
          'id': id,
          ..._providerMetadataJson(providerMetadata),
        },
      TextDeltaEvent(:final id, :final delta, :final providerMetadata) => {
          'type': 'text-delta',
          'id': id,
          'delta': delta,
          ..._providerMetadataJson(providerMetadata),
        },
      TextEndEvent(:final id, :final providerMetadata) => {
          'type': 'text-end',
          'id': id,
          ..._providerMetadataJson(providerMetadata),
        },
      ReasoningStartEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-start',
          'id': id,
          ..._providerMetadataJson(providerMetadata),
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
          ..._providerMetadataJson(providerMetadata),
        },
      ReasoningEndEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-end',
          'id': id,
          ..._providerMetadataJson(providerMetadata),
        },
      ReasoningFileEvent(:final file, :final providerMetadata) => {
          'type': 'reasoning-file',
          'file': provider.SerializationJsonSupport.encodeGeneratedFile(file),
          ..._providerMetadataJson(providerMetadata),
        },
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a text or reasoning content stream event.',
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
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'text-delta' => TextDeltaEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          delta: provider.asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'text-end' => TextEndEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'reasoning-start' => ReasoningStartEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'reasoning-delta' => ReasoningDeltaEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          delta: provider.asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'reasoning-end' => ReasoningEndEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'reasoning-file' => ReasoningFileEvent(
          provider.SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      _ => throw FormatException(
          'Unsupported text content stream event type "$type" at $path.',
        ),
    };
  }

  provider.JsonMap _providerMetadataJson(
    provider.ProviderMetadata? providerMetadata,
  ) {
    if (providerMetadata == null) {
      return const {};
    }

    return {
      'providerMetadata':
          provider.SerializationJsonSupport.encodeProviderMetadata(
        providerMetadata,
      ),
    };
  }

  provider.ProviderMetadata? _decodeProviderMetadata(
    provider.JsonMap map, {
    required String path,
  }) {
    return provider.SerializationJsonSupport.decodeProviderMetadata(
      map['providerMetadata'],
      path: '$path.providerMetadata',
    );
  }
}
