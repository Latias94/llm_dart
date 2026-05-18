import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_sse_encoder.dart';
import 'http_chat_transport_stream_protocol.dart';

export 'http_chat_transport_sse_encoder.dart' show HttpChatTransportSseEncoder;

final class HttpChatTransportServerAdapter {
  final HttpChatTransportSseEncoder sseEncoder;

  const HttpChatTransportServerAdapter({
    this.sseEncoder = const HttpChatTransportSseEncoder(),
  });

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
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
    String? requestId,
    String? defaultMessageId,
    String? resumeToken,
    bool emitTransportFinish = true,
  }) async* {
    var emittedLegacyStart = false;

    HttpChatTransportStartChunk? takeLegacyStartChunk({
      String? overrideMessageId,
    }) {
      if (emittedLegacyStart) {
        return null;
      }

      final resolvedMessageId = overrideMessageId ?? defaultMessageId;
      if (requestId == null &&
          resolvedMessageId == null &&
          resumeToken == null) {
        return null;
      }

      emittedLegacyStart = true;
      return HttpChatTransportStartChunk(
        requestId: requestId,
        messageId: resolvedMessageId,
        resumeToken: resumeToken,
      );
    }

    if (streamProtocol == HttpChatTransportStreamProtocol.uiMessageStreamV2 &&
        (requestId != null || resumeToken != null)) {
      yield HttpChatTransportTransportStartChunk(
        requestId: requestId,
        resumeToken: resumeToken,
      );
    }

    await for (final chunk in stream) {
      if (streamProtocol == HttpChatTransportStreamProtocol.eventStreamV1) {
        final startChunk = switch (chunk) {
          ChatUiMessageStartChunk(:final messageId) => takeLegacyStartChunk(
              overrideMessageId: messageId,
            ),
          _ => takeLegacyStartChunk(),
        };

        if (startChunk != null) {
          yield startChunk;
        }
      }

      switch (chunk) {
        case ChatUiMessageStartChunk(
            :final messageId,
            :final metadata,
          ):
          if (streamProtocol ==
              HttpChatTransportStreamProtocol.uiMessageStreamV2) {
            final resolvedMessageId = messageId ?? defaultMessageId;
            if (resolvedMessageId != null) {
              yield HttpChatTransportMessageStartChunk(
                messageId: resolvedMessageId,
                metadata: metadata,
              );
            } else if (metadata.isNotEmpty) {
              yield HttpChatTransportMessageMetadataChunk(
                metadata: metadata,
              );
            }
          }
        case ChatUiMessageMetadataChunk(:final metadata):
          if (streamProtocol ==
              HttpChatTransportStreamProtocol.uiMessageStreamV2) {
            yield HttpChatTransportMessageMetadataChunk(
              metadata: metadata,
            );
          }
        case ChatUiEventChunk(:final event):
          yield HttpChatTransportEventChunk(event);
        case ChatUiDataPartChunk(:final part):
          yield HttpChatTransportDataPartChunk(
            DataUiPart<Object?>(
              id: part.id,
              key: part.key,
              data: part.data,
            ),
          );
        case ChatUiTransientDataPartChunk(:final part):
          if (streamProtocol ==
              HttpChatTransportStreamProtocol.uiMessageStreamV2) {
            yield HttpChatTransportTransientDataPartChunk(
              DataUiPart<Object?>(
                id: part.id,
                key: part.key,
                data: part.data,
              ),
            );
          }
        case ChatUiMessageFinishChunk(:final metadata):
          if (streamProtocol ==
              HttpChatTransportStreamProtocol.uiMessageStreamV2) {
            yield HttpChatTransportMessageFinishChunk(
              metadata: metadata,
            );
          }
      }
    }

    if (streamProtocol == HttpChatTransportStreamProtocol.eventStreamV1) {
      final startChunk = takeLegacyStartChunk();
      if (startChunk != null) {
        yield startChunk;
      }
    }

    if (emitTransportFinish) {
      yield const HttpChatTransportFinishChunk();
    }
  }

  Stream<HttpChatTransportChunk> encodeEventStream({
    required Stream<TextStreamEvent> eventStream,
    HttpChatTransportStreamProtocol streamProtocol =
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
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
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
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
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
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
