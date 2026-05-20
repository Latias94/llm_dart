import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';

final class ChatUiTextPartJsonCodec {
  static const Set<String> partTypes = {
    'text',
    'reasoning',
  };

  const ChatUiTextPartJsonCodec();

  bool canDecode(String type) => partTypes.contains(type);

  JsonMap encode(ChatUiPart part) {
    return switch (part) {
      TextUiPart(
        :final text,
        :final isStreaming,
        :final providerMetadata,
      ) =>
        {
          'type': 'text',
          'text': text,
          'isStreaming': isStreaming,
          ..._providerMetadataJson(providerMetadata),
        },
      ReasoningUiPart(
        :final text,
        :final isStreaming,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning',
          'text': text,
          'isStreaming': isStreaming,
          ..._providerMetadataJson(providerMetadata),
        },
      _ => throw ArgumentError.value(
          part,
          'part',
          'Expected a text or reasoning chat UI part.',
        ),
    };
  }

  ChatUiPart decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'text' => TextUiPart(
          text: asJsonString(map['text'], path: '$path.text'),
          isStreaming: asNullableJsonBool(
                map['isStreaming'],
                path: '$path.isStreaming',
              ) ??
              false,
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      'reasoning' => ReasoningUiPart(
          text: asJsonString(map['text'], path: '$path.text'),
          isStreaming: asNullableJsonBool(
                map['isStreaming'],
                path: '$path.isStreaming',
              ) ??
              false,
          providerMetadata: _decodeProviderMetadata(map, path: path),
        ),
      _ => throw FormatException(
          'Unsupported text chat UI part type "$type" at $path.',
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
