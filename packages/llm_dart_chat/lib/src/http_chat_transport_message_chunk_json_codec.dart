import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_json_support.dart';

final class HttpChatTransportMessageChunkJsonCodec {
  static const Set<String> chunkTypes = {
    'message-start',
    'message-metadata',
    'message-finish',
  };

  const HttpChatTransportMessageChunkJsonCodec();

  bool canDecode(String type) => chunkTypes.contains(type);

  Map<String, Object?> encode(HttpChatTransportChunk chunk) {
    return switch (chunk) {
      HttpChatTransportMessageStartChunk(:final messageId, :final metadata) => {
          'type': 'message-start',
          'messageId': messageId,
          if (metadata.isNotEmpty) 'metadata': metadata,
        },
      HttpChatTransportMessageMetadataChunk(:final metadata) => {
          'type': 'message-metadata',
          'metadata': metadata,
        },
      HttpChatTransportMessageFinishChunk(:final metadata) => {
          'type': 'message-finish',
          if (metadata.isNotEmpty) 'metadata': metadata,
        },
      _ => throw ArgumentError.value(
          chunk,
          'chunk',
          'Expected an HTTP chat transport message chunk.',
        ),
    };
  }

  HttpChatTransportChunk decode(
    Map<String, Object?> data, {
    required String type,
  }) {
    return switch (type) {
      'message-start' => HttpChatTransportMessageStartChunk(
          messageId: HttpChatTransportJson.asString(
            data['messageId'],
            path: r'$.data.messageId',
          ),
          metadata: _decodeOptionalMetadata(data),
        ),
      'message-metadata' => HttpChatTransportMessageMetadataChunk(
          metadata: HttpChatTransportJson.asMap(
            data['metadata'],
            path: r'$.data.metadata',
          ),
        ),
      'message-finish' => HttpChatTransportMessageFinishChunk(
          metadata: _decodeOptionalMetadata(data),
        ),
      _ => throw FormatException(
          'Unsupported HTTP chat transport message chunk type "$type".',
        ),
    };
  }

  Map<String, Object?> _decodeOptionalMetadata(Map<String, Object?> data) {
    if (data['metadata'] == null) {
      return const {};
    }

    return HttpChatTransportJson.asMap(
      data['metadata'],
      path: r'$.data.metadata',
    );
  }
}
