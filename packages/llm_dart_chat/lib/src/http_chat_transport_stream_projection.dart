import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_resume_state.dart';

sealed class HttpChatTransportProjectedChunk {
  const HttpChatTransportProjectedChunk();
}

final class HttpChatTransportEmitChunk extends HttpChatTransportProjectedChunk {
  final List<ChatUiStreamChunk> chunks;
  final bool terminateStream;

  HttpChatTransportEmitChunk(
    ChatUiStreamChunk chunk, {
    this.terminateStream = false,
  }) : chunks = List.unmodifiable([chunk]);

  HttpChatTransportEmitChunk.many(
    Iterable<ChatUiStreamChunk> chunks, {
    this.terminateStream = false,
  }) : chunks = List.unmodifiable(chunks);
}

final class HttpChatTransportNoopChunk extends HttpChatTransportProjectedChunk {
  const HttpChatTransportNoopChunk();
}

HttpChatTransportProjectedChunk projectHttpChatTransportChunk({
  required HttpChatTransportChunk chunk,
  required HttpChatTransportResumeState state,
  required void Function() clearResumeState,
}) {
  switch (chunk) {
    case HttpChatTransportTransportStartChunk(:final resumeToken):
      if (resumeToken != null) {
        state.resumeToken = resumeToken;
      }
      return const HttpChatTransportNoopChunk();
    case HttpChatTransportStartChunk(
        :final resumeToken,
        :final messageId,
      ):
      if (resumeToken != null) {
        state.resumeToken = resumeToken;
      }
      if (messageId == null) {
        return const HttpChatTransportNoopChunk();
      }

      return _replay(
        state,
        ChatUiMessageStartChunk(
          messageId: messageId,
        ),
      );
    case HttpChatTransportMessageStartChunk(
        :final messageId,
        :final metadata,
      ):
      return _replay(
        state,
        ChatUiMessageStartChunk(
          messageId: messageId,
          metadata: metadata,
        ),
      );
    case HttpChatTransportMessageMetadataChunk(:final metadata):
      return _replay(
        state,
        ChatUiMessageMetadataChunk(
          metadata: metadata,
        ),
      );
    case HttpChatTransportEventChunk(:final event):
      final projected = _replay(state, ChatUiEventChunk(event));
      if (event is FinishEvent) {
        clearResumeState();
      }
      return projected;
    case HttpChatTransportDataPartChunk(:final part):
      return _replay(state, ChatUiDataPartChunk<Object?>(part));
    case HttpChatTransportTransientDataPartChunk(:final part):
      return HttpChatTransportEmitChunk(
        ChatUiTransientDataPartChunk<Object?>(part),
      );
    case HttpChatTransportAbortChunk(:final reason):
      clearResumeState();
      return HttpChatTransportEmitChunk.many(
        [
          ChatUiEventChunk(
            AbortEvent(
              reason: reason,
            ),
          ),
          projectHttpChatTransportAbortFinish(reason),
        ],
        terminateStream: true,
      );
    case HttpChatTransportErrorChunk(
        :final code,
        :final message,
        :final details,
      ):
      clearResumeState();
      return HttpChatTransportEmitChunk(
        ChatUiEventChunk(
          ErrorEvent(
            ModelError(
              kind: ModelErrorKind.transport,
              message: message,
              code: code ?? 'http-chat-transport-error',
              isRetryable: switch (details) {
                {
                  'retryable': final bool retryable,
                } =>
                  retryable,
                _ => null,
              },
              details: details,
            ),
          ),
        ),
        terminateStream: true,
      );
    case HttpChatTransportCheckpointChunk(:final resumeToken):
      state.resumeToken = resumeToken;
      return const HttpChatTransportNoopChunk();
    case HttpChatTransportMessageFinishChunk(:final metadata):
      return _replay(
        state,
        ChatUiMessageFinishChunk(
          metadata: metadata,
        ),
      );
    case HttpChatTransportFinishChunk():
      if (state.isTerminal) {
        clearResumeState();
      }
      return const HttpChatTransportNoopChunk();
    case HttpChatTransportKeepAliveChunk():
      return const HttpChatTransportNoopChunk();
  }
}

ChatUiEventChunk projectHttpChatTransportAbortFinish(String? reason) {
  return ChatUiEventChunk(
    FinishEvent(
      finishReason: FinishReason.aborted,
      rawFinishReason: reason,
    ),
  );
}

HttpChatTransportEmitChunk _replay(
  HttpChatTransportResumeState state,
  ChatUiStreamChunk replayChunk,
) {
  state.replayChunks.add(replayChunk);
  return HttpChatTransportEmitChunk(replayChunk);
}
