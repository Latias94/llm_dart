import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_stream_protocol.dart';

final class HttpChatTransportServerProjection {
  const HttpChatTransportServerProjection();

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

      for (final projected in _projectUiChunk(
        chunk,
        streamProtocol: streamProtocol,
        defaultMessageId: defaultMessageId,
      )) {
        yield projected;
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

  Iterable<HttpChatTransportChunk> _projectUiChunk(
    ChatUiStreamChunk chunk, {
    required HttpChatTransportStreamProtocol streamProtocol,
    required String? defaultMessageId,
  }) sync* {
    switch (chunk) {
      case ChatUiMessageStartChunk(:final messageId, :final metadata):
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
}
