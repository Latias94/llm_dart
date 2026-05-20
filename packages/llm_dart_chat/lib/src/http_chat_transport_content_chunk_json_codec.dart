import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_data_part_json_codec.dart';

final class HttpChatTransportContentChunkJsonCodec {
  static const Set<String> chunkTypes = {
    'event',
    'data-part',
    'transient-data-part',
  };

  final TextStreamEventJsonCodec eventCodec;
  final HttpChatTransportDataPartJsonCodec dataPartCodec;

  const HttpChatTransportContentChunkJsonCodec({
    this.eventCodec = const TextStreamEventJsonCodec(),
    this.dataPartCodec = const HttpChatTransportDataPartJsonCodec(),
  });

  bool canDecode(String type) => chunkTypes.contains(type);

  Map<String, Object?> encode(HttpChatTransportChunk chunk) {
    return switch (chunk) {
      HttpChatTransportEventChunk(:final event) => {
          'type': 'event',
          'event': eventCodec.encodeEvent(event),
        },
      HttpChatTransportDataPartChunk(:final part) => {
          'type': 'data-part',
          'part': dataPartCodec.encodePart(part, path: r'$.data.part'),
        },
      HttpChatTransportTransientDataPartChunk(:final part) => {
          'type': 'transient-data-part',
          'part': dataPartCodec.encodePart(part, path: r'$.data.part'),
        },
      _ => throw ArgumentError.value(
          chunk,
          'chunk',
          'Expected an HTTP chat transport content chunk.',
        ),
    };
  }

  HttpChatTransportChunk decode(
    Map<String, Object?> data, {
    required String type,
  }) {
    return switch (type) {
      'event' => HttpChatTransportEventChunk(
          eventCodec.decodeEvent(data['event'], path: r'$.data.event'),
        ),
      'data-part' => HttpChatTransportDataPartChunk(
          dataPartCodec.decodePart(data['part'], path: r'$.data.part'),
        ),
      'transient-data-part' => HttpChatTransportTransientDataPartChunk(
          dataPartCodec.decodePart(data['part'], path: r'$.data.part'),
        ),
      _ => throw FormatException(
          'Unsupported HTTP chat transport content chunk type "$type".',
        ),
    };
  }
}
