import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import 'client.dart';
import 'google_chat_response.dart';

part 'google_chat_stream_event_support.dart';
part 'google_chat_stream_frame_buffer.dart';
part 'google_chat_stream_frame_buffer_json_support.dart';
part 'google_chat_stream_frame_buffer_sse_support.dart';
part 'google_chat_stream_payload_decoder.dart';

/// Stateful streaming support for Google chat parsing.
final class GoogleChatStreamSupport {
  final GoogleClient client;
  late final _GoogleChatStreamFrameBuffer _frameBuffer;
  late final _GoogleChatStreamPayloadDecoder _payloadDecoder;
  late final _GoogleChatStreamEventSupport _eventSupport;

  GoogleChatStreamSupport({
    required this.client,
  }) {
    _frameBuffer = _GoogleChatStreamFrameBuffer(client: client);
    _payloadDecoder = const _GoogleChatStreamPayloadDecoder();
    _eventSupport = const _GoogleChatStreamEventSupport();
  }

  void reset() {
    _frameBuffer.reset();
  }

  List<ChatStreamEvent> parseChunk(String chunk) {
    final events = <ChatStreamEvent>[];
    final payloads = _frameBuffer.absorbChunk(chunk);

    for (final payload in payloads) {
      final decodedPayloads = _payloadDecoder.decode(payload);
      for (final decodedPayload in decodedPayloads) {
        events.addAll(_eventSupport.mapPayload(decodedPayload));
      }
    }

    return events;
  }
}
