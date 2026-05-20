import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_content_chunk_json_codec.dart';
import 'http_chat_transport_data_part_json_codec.dart';
import 'http_chat_transport_json_support.dart';
import 'http_chat_transport_lifecycle_chunk_json_codec.dart';
import 'http_chat_transport_message_chunk_json_codec.dart';

final class HttpChatTransportChunkJsonCodec {
  static const envelopeKind = 'http-chat-transport-chunk';

  final TextStreamEventJsonCodec eventCodec;
  final HttpChatTransportDataPartJsonCodec dataPartCodec;

  const HttpChatTransportChunkJsonCodec({
    this.eventCodec = const TextStreamEventJsonCodec(),
    this.dataPartCodec = const HttpChatTransportDataPartJsonCodec(),
  });

  Map<String, Object?> encodeChunk(HttpChatTransportChunk chunk) {
    final data = switch (chunk) {
      HttpChatTransportTransportStartChunk() ||
      HttpChatTransportStartChunk() ||
      HttpChatTransportCheckpointChunk() ||
      HttpChatTransportFinishChunk() ||
      HttpChatTransportAbortChunk() ||
      HttpChatTransportErrorChunk() ||
      HttpChatTransportKeepAliveChunk() =>
        const HttpChatTransportLifecycleChunkJsonCodec().encode(chunk),
      HttpChatTransportMessageStartChunk() ||
      HttpChatTransportMessageMetadataChunk() ||
      HttpChatTransportMessageFinishChunk() =>
        const HttpChatTransportMessageChunkJsonCodec().encode(chunk),
      HttpChatTransportEventChunk() ||
      HttpChatTransportDataPartChunk() ||
      HttpChatTransportTransientDataPartChunk() =>
        HttpChatTransportContentChunkJsonCodec(
          eventCodec: eventCodec,
          dataPartCodec: dataPartCodec,
        ).encode(chunk),
    };

    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': data,
    };
  }

  HttpChatTransportChunk decodeChunk(Object? envelope) {
    final root = HttpChatTransportJson.asMap(envelope, path: r'$');
    final kind = HttpChatTransportJson.asString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = HttpChatTransportJson.asMap(root['data'], path: r'$.data');
    final type = HttpChatTransportJson.asString(
      data['type'],
      path: r'$.data.type',
    );

    const lifecycleCodec = HttpChatTransportLifecycleChunkJsonCodec();
    if (lifecycleCodec.canDecode(type)) {
      return lifecycleCodec.decode(data, type: type);
    }

    const messageCodec = HttpChatTransportMessageChunkJsonCodec();
    if (messageCodec.canDecode(type)) {
      return messageCodec.decode(data, type: type);
    }

    final contentCodec = HttpChatTransportContentChunkJsonCodec(
      eventCodec: eventCodec,
      dataPartCodec: dataPartCodec,
    );
    if (contentCodec.canDecode(type)) {
      return contentCodec.decode(data, type: type);
    }

    throw FormatException(
      'Unsupported HTTP chat transport chunk type "$type".',
    );
  }
}
