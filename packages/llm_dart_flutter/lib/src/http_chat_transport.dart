import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'chat_transport.dart';
import 'http_chat_transport_protocol.dart';

final class HttpChatTransport implements ChatTransport {
  final Uri endpoint;
  final TransportClient transport;
  final SseDecoder sseDecoder;
  final HttpChatTransportRequestJsonCodec requestCodec;
  final HttpChatTransportChunkJsonCodec chunkCodec;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final Map<String, _HttpChatTransportResumeState> _resumeStates = {};

  HttpChatTransport({
    required this.endpoint,
    required this.transport,
    this.sseDecoder = const DefaultSseDecoder(),
    this.requestCodec = const HttpChatTransportRequestJsonCodec(),
    this.chunkCodec = const HttpChatTransportChunkJsonCodec(),
    this.headers = const {},
    this.requestTimeout,
  });

  @override
  Stream<ChatTransportChunk> sendMessages(ChatTransportRequest request) async* {
    _ensureSupportedCallOptions(request.options.callOptions);

    final state = _HttpChatTransportResumeState();
    _resumeStates[request.chatId] = state;

    final payload = requestCodec.encodeRequest(
      HttpChatTransportRequestPayload(
        chatId: request.chatId,
        prompt: request.prompt,
        generateOptions: request.options.generateOptions,
      ),
    );

    yield* _sendPayload(
      chatId: request.chatId,
      state: state,
      payload: payload,
    );
  }

  @override
  Stream<ChatTransportChunk>? reconnect(String chatId) {
    final state = _resumeStates[chatId];
    final resumeToken = state?.resumeToken;
    if (state == null || resumeToken == null) {
      return null;
    }

    final replayChunks = List<ChatTransportChunk>.of(state.replayChunks);
    final payload = requestCodec.encodeReconnectRequest(
      HttpChatTransportReconnectRequestPayload(
        chatId: chatId,
        resumeToken: resumeToken,
      ),
    );

    return _reconnectWithReplay(
      chatId: chatId,
      state: state,
      payload: payload,
      replayChunks: replayChunks,
    );
  }

  Stream<ChatTransportChunk> _reconnectWithReplay({
    required String chatId,
    required _HttpChatTransportResumeState state,
    required Map<String, Object?> payload,
    required List<ChatTransportChunk> replayChunks,
  }) async* {
    yield* Stream<ChatTransportChunk>.fromIterable(replayChunks);
    yield* _sendPayload(
      chatId: chatId,
      state: state,
      payload: payload,
    );
  }

  Stream<ChatTransportChunk> _sendPayload({
    required String chatId,
    required _HttpChatTransportResumeState state,
    required Map<String, Object?> payload,
  }) async* {
    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: endpoint,
          method: TransportMethod.post,
          headers: {
            'content-type': 'application/json',
            'accept': 'text/event-stream',
            ...headers,
          },
          body: payload,
          timeout: requestTimeout,
          responseType: TransportResponseType.plainText,
        ),
      );

      if (response.statusCode >= 400) {
        _clearResumeState(chatId, state);
        yield ChatTransportEventChunk(
          ErrorEvent(
            ModelError(
              kind: ModelErrorKind.transport,
              message: 'HTTP chat transport request failed.',
              code: 'http-transport-status',
              statusCode: response.statusCode,
              isRetryable: response.statusCode >= 500 ||
                  response.statusCode == 408 ||
                  response.statusCode == 409 ||
                  response.statusCode == 429,
            ),
          ),
        );
        return;
      }

      final parser = SseJsonChunkParser(sseDecoder: sseDecoder);
      await for (final envelope in parser.parse(response.stream)) {
        final chunk = chunkCodec.decodeChunk(envelope);
        switch (chunk) {
          case HttpChatTransportStartChunk(:final resumeToken):
            if (resumeToken != null) {
              state.resumeToken = resumeToken;
            }
          case HttpChatTransportEventChunk(:final event):
            final replayChunk = ChatTransportEventChunk(event);
            state.replayChunks.add(replayChunk);
            if (event is FinishEvent) {
              _clearResumeState(chatId, state);
            }
            yield replayChunk;
          case HttpChatTransportDataPartChunk(:final part):
            final replayChunk = ChatTransportDataPartChunk(part);
            state.replayChunks.add(replayChunk);
            yield replayChunk;
          case HttpChatTransportAbortChunk(:final reason):
            _clearResumeState(chatId, state);
            yield ChatTransportEventChunk(
              FinishEvent(
                finishReason: FinishReason.aborted,
                rawFinishReason: reason,
              ),
            );
            return;
          case HttpChatTransportErrorChunk(
              :final code,
              :final message,
              :final details,
            ):
            _clearResumeState(chatId, state);
            yield ChatTransportEventChunk(
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
            );
            return;
          case HttpChatTransportCheckpointChunk(:final resumeToken):
            state.resumeToken = resumeToken;
          case HttpChatTransportFinishChunk():
            if (state.isTerminal) {
              _clearResumeState(chatId, state);
            }
          case HttpChatTransportKeepAliveChunk():
            break;
        }
      }
    } catch (error) {
      if (!state.canReconnect) {
        _clearResumeState(chatId, state);
      }
      yield ChatTransportEventChunk(
        ErrorEvent(transportErrorToModelError(error)),
      );
    }
  }

  void _ensureSupportedCallOptions(CallOptions options) {
    if (options.timeout != null ||
        options.headers != null ||
        options.providerOptions != null) {
      throw UnsupportedError(
        'HttpChatTransport does not serialize CallOptions yet. Configure backend transport behavior on the transport itself, not through provider invocation options.',
      );
    }
  }

  void _clearResumeState(
    String chatId,
    _HttpChatTransportResumeState state,
  ) {
    if (identical(_resumeStates[chatId], state)) {
      _resumeStates.remove(chatId);
    }
    state.isTerminal = true;
  }
}

final class _HttpChatTransportResumeState {
  final List<ChatTransportChunk> replayChunks = [];
  String? resumeToken;
  bool isTerminal = false;

  bool get canReconnect => !isTerminal && resumeToken != null;
}
