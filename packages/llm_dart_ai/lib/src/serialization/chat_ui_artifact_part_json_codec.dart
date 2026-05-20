import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';

final class ChatUiArtifactPartJsonCodec {
  static const Set<String> partTypes = {
    'source',
    'file',
    'reasoning-file',
    'custom',
  };

  const ChatUiArtifactPartJsonCodec();

  bool canDecode(String type) => partTypes.contains(type);

  JsonMap encode(ChatUiPart part) {
    return switch (part) {
      SourceUiPart(:final source) => {
          'type': 'source',
          'source': SerializationJsonSupport.encodeSourceReference(source),
        },
      FileUiPart(:final file, :final providerMetadata) => {
          'type': 'file',
          'file': SerializationJsonSupport.encodeGeneratedFile(file),
          ..._providerMetadataJson(providerMetadata),
        },
      ReasoningFileUiPart(:final file, :final providerMetadata) => {
          'type': 'reasoning-file',
          'file': SerializationJsonSupport.encodeGeneratedFile(file),
          ..._providerMetadataJson(providerMetadata),
        },
      CustomUiPart(:final kind, :final data, :final providerMetadata) => {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(data, path: r'$.custom.data'),
          ..._providerMetadataJson(providerMetadata),
        },
      _ => throw ArgumentError.value(
          part,
          'part',
          'Expected a source, file, reasoning file, or custom chat UI part.',
        ),
    };
  }

  ChatUiPart decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'source' => SourceUiPart(
          SerializationJsonSupport.decodeSourceReference(
            map['source'],
            path: '$path.source',
          ),
        ),
      'file' => FileUiPart(
          SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'reasoning-file' => ReasoningFileUiPart(
          SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'custom' => CustomUiPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      _ => throw FormatException(
          'Unsupported artifact chat UI part type "$type" at $path.',
        ),
    };
  }

  JsonMap _providerMetadataJson(ProviderMetadata? providerMetadata) {
    if (providerMetadata == null) {
      return const {};
    }

    return {
      'providerMetadata':
          SerializationJsonSupport.encodeProviderMetadata(providerMetadata),
    };
  }

  ProviderMetadata? _decodeProviderMetadata(
    JsonMap map, {
    required String path,
  }) {
    return SerializationJsonSupport.decodeProviderMetadata(
      map['providerMetadata'],
      path: '$path.providerMetadata',
    );
  }
}
