import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_protocol_policy.dart';
import 'http_chat_transport_server_projection.dart';
import 'http_chat_transport_sse_encoder.dart';
import 'http_chat_transport_stream_protocol.dart';

export 'http_chat_transport_sse_encoder.dart' show HttpChatTransportSseEncoder;

final class HttpChatTransportServerAdapter {
  final HttpChatTransportSseEncoder sseEncoder;
  final HttpChatTransportServerProjection _serverProjection;

  const HttpChatTransportServerAdapter({
    this.sseEncoder = const HttpChatTransportSseEncoder(),
  }) : _serverProjection = const HttpChatTransportServerProjection();

  Stream<ChatUiStreamChunk> wrapEventStream({
    required Stream<TextStreamEvent> eventStream,
    String? messageId,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
  }) {
    return projectTextStreamEventStream(
      eventStream,
      messageId: messageId,
      messageMetadata: messageMetadata,
      leadingDataParts: leadingDataParts,
      finalMessageMetadata: finalMessageMetadata,
    );
  }

  Stream<HttpChatTransportChunk> encodeUiChunkStream({
    required Stream<ChatUiStreamChunk> stream,
    HttpChatTransportStreamProtocol streamProtocol =
        HttpChatTransportProtocolPolicy.defaultStreamProtocol,
    String? requestId,
    String? defaultMessageId,
    String? resumeToken,
    bool emitTransportFinish = true,
  }) {
    return _serverProjection.encodeUiChunkStream(
      stream: stream,
      streamProtocol: streamProtocol,
      requestId: requestId,
      defaultMessageId: defaultMessageId,
      resumeToken: resumeToken,
      emitTransportFinish: emitTransportFinish,
    );
  }

  Stream<HttpChatTransportChunk> encodeEventStream({
    required Stream<TextStreamEvent> eventStream,
    HttpChatTransportStreamProtocol streamProtocol =
        HttpChatTransportProtocolPolicy.defaultStreamProtocol,
    String? requestId,
    String? messageId,
    String? resumeToken,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
    bool emitTransportFinish = true,
  }) {
    return encodeUiChunkStream(
      stream: wrapEventStream(
        eventStream: eventStream,
        messageId: messageId,
        messageMetadata: messageMetadata,
        leadingDataParts: leadingDataParts,
        finalMessageMetadata: finalMessageMetadata,
      ),
      streamProtocol: streamProtocol,
      requestId: requestId,
      defaultMessageId: messageId,
      resumeToken: resumeToken,
      emitTransportFinish: emitTransportFinish,
    );
  }

  Stream<List<int>> encodeUiSseStream({
    required Stream<ChatUiStreamChunk> stream,
    HttpChatTransportStreamProtocol streamProtocol =
        HttpChatTransportProtocolPolicy.defaultStreamProtocol,
    String? requestId,
    String? messageId,
    String? resumeToken,
    bool emitTransportFinish = true,
    bool includeDoneFrame = false,
  }) {
    return sseEncoder.encodeChunkStream(
      encodeUiChunkStream(
        stream: stream,
        streamProtocol: streamProtocol,
        requestId: requestId,
        defaultMessageId: messageId,
        resumeToken: resumeToken,
        emitTransportFinish: emitTransportFinish,
      ),
      includeDoneFrame: includeDoneFrame,
    );
  }

  Stream<List<int>> encodeEventSseStream({
    required Stream<TextStreamEvent> eventStream,
    HttpChatTransportStreamProtocol streamProtocol =
        HttpChatTransportProtocolPolicy.defaultStreamProtocol,
    String? requestId,
    String? messageId,
    String? resumeToken,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
    bool emitTransportFinish = true,
    bool includeDoneFrame = false,
  }) {
    return sseEncoder.encodeChunkStream(
      encodeEventStream(
        eventStream: eventStream,
        streamProtocol: streamProtocol,
        requestId: requestId,
        messageId: messageId,
        resumeToken: resumeToken,
        messageMetadata: messageMetadata,
        leadingDataParts: leadingDataParts,
        finalMessageMetadata: finalMessageMetadata,
        emitTransportFinish: emitTransportFinish,
      ),
      includeDoneFrame: includeDoneFrame,
    );
  }
}
