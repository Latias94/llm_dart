import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'chat_transport.dart';

typedef PrepareSendMessagesRequest
    = FutureOr<HttpChatTransportPreparedSendMessagesRequest?> Function(
  HttpChatTransportSendMessagesRequestContext context,
);

typedef PrepareReconnectRequest
    = FutureOr<HttpChatTransportPreparedReconnectRequest?> Function(
  HttpChatTransportReconnectRequestContext context,
);

final class HttpChatTransportSendMessagesRequestContext {
  final ChatTransportRequest request;
  final Uri endpoint;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final HttpChatTransportRequestPayload payload;

  const HttpChatTransportSendMessagesRequestContext({
    required this.request,
    required this.endpoint,
    required this.headers,
    required this.requestTimeout,
    required this.payload,
  });
}

final class HttpChatTransportPreparedSendMessagesRequest {
  final Uri? endpoint;
  final Map<String, String>? headers;
  final Duration? requestTimeout;
  final bool overrideRequestTimeout;
  final HttpChatTransportRequestPayload? payload;

  const HttpChatTransportPreparedSendMessagesRequest({
    this.endpoint,
    this.headers,
    this.requestTimeout,
    this.overrideRequestTimeout = false,
    this.payload,
  });
}

final class HttpChatTransportReconnectRequestContext {
  final String chatId;
  final String resumeToken;
  final Uri endpoint;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final HttpChatTransportReconnectRequestPayload payload;

  const HttpChatTransportReconnectRequestContext({
    required this.chatId,
    required this.resumeToken,
    required this.endpoint,
    required this.headers,
    required this.requestTimeout,
    required this.payload,
  });
}

final class HttpChatTransportPreparedReconnectRequest {
  final Uri? endpoint;
  final Map<String, String>? headers;
  final Duration? requestTimeout;
  final bool overrideRequestTimeout;
  final HttpChatTransportReconnectRequestPayload? payload;

  const HttpChatTransportPreparedReconnectRequest({
    this.endpoint,
    this.headers,
    this.requestTimeout,
    this.overrideRequestTimeout = false,
    this.payload,
  });
}

final class HttpChatTransport implements ChatTransport {
  final Uri endpoint;
  final TransportClient transport;
  final SseDecoder sseDecoder;
  final HttpChatTransportRequestJsonCodec requestCodec;
  final HttpChatTransportChunkJsonCodec chunkCodec;
  final HttpChatTransportStreamProtocol streamProtocol;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final PrepareSendMessagesRequest? prepareSendMessagesRequest;
  final PrepareReconnectRequest? prepareReconnectRequest;
  final Map<String, _HttpChatTransportResumeState> _resumeStates = {};

  HttpChatTransport({
    required this.endpoint,
    required this.transport,
    this.sseDecoder = const DefaultSseDecoder(),
    this.requestCodec = const HttpChatTransportRequestJsonCodec(),
    this.chunkCodec = const HttpChatTransportChunkJsonCodec(),
    this.streamProtocol = HttpChatTransportStreamProtocol.uiMessageStreamV2,
    this.headers = const {},
    this.requestTimeout,
    this.prepareSendMessagesRequest,
    this.prepareReconnectRequest,
  });

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) async* {
    _ensureSupportedCallOptions(request.options.callOptions);

    final state = _HttpChatTransportResumeState();
    _resumeStates[request.chatId] = state;

    final baseHeaders = _baseHeaders();
    final basePayload = HttpChatTransportRequestPayload(
      chatId: request.chatId,
      prompt: request.prompt,
      generateOptions: request.options.generateOptions,
      streamProtocol: streamProtocol,
      metadata: request.options.metadata,
    );
    final preparedRequest = await prepareSendMessagesRequest?.call(
      HttpChatTransportSendMessagesRequestContext(
        request: request,
        endpoint: endpoint,
        headers: Map.unmodifiable(baseHeaders),
        requestTimeout: requestTimeout,
        payload: basePayload,
      ),
    );
    final resolvedPayload = preparedRequest?.payload ?? basePayload;
    final payload = requestCodec.encodeRequest(resolvedPayload);
    final resolvedHeaders = preparedRequest?.headers ?? baseHeaders;
    final resolvedEndpoint = preparedRequest?.endpoint ?? endpoint;
    final resolvedRequestTimeout =
        preparedRequest?.overrideRequestTimeout == true
            ? preparedRequest!.requestTimeout
            : requestTimeout;

    yield* _sendPayload(
      chatId: request.chatId,
      state: state,
      endpoint: resolvedEndpoint,
      headers: resolvedHeaders,
      requestTimeout: resolvedRequestTimeout,
      payload: payload,
    );
  }

  @override
  Stream<ChatUiStreamChunk>? reconnect(String chatId) {
    final state = _resumeStates[chatId];
    final resumeToken = state?.resumeToken;
    if (state == null || resumeToken == null) {
      return null;
    }

    final replayChunks = List<ChatUiStreamChunk>.of(state.replayChunks);

    return _reconnectWithReplay(
      chatId: chatId,
      resumeToken: resumeToken,
      state: state,
      replayChunks: replayChunks,
    );
  }

  Stream<ChatUiStreamChunk> _reconnectWithReplay({
    required String chatId,
    required String resumeToken,
    required _HttpChatTransportResumeState state,
    required List<ChatUiStreamChunk> replayChunks,
  }) async* {
    final baseHeaders = _baseHeaders();
    final basePayload = HttpChatTransportReconnectRequestPayload(
      chatId: chatId,
      resumeToken: resumeToken,
      streamProtocol: streamProtocol,
    );
    final preparedRequest = await prepareReconnectRequest?.call(
      HttpChatTransportReconnectRequestContext(
        chatId: chatId,
        resumeToken: resumeToken,
        endpoint: endpoint,
        headers: Map.unmodifiable(baseHeaders),
        requestTimeout: requestTimeout,
        payload: basePayload,
      ),
    );
    final resolvedPayload = preparedRequest?.payload ?? basePayload;
    final payload = requestCodec.encodeReconnectRequest(resolvedPayload);
    final resolvedHeaders = preparedRequest?.headers ?? baseHeaders;
    final resolvedEndpoint = preparedRequest?.endpoint ?? endpoint;
    final resolvedRequestTimeout =
        preparedRequest?.overrideRequestTimeout == true
            ? preparedRequest!.requestTimeout
            : requestTimeout;

    yield* Stream<ChatUiStreamChunk>.fromIterable(replayChunks);
    yield* _sendPayload(
      chatId: chatId,
      state: state,
      endpoint: resolvedEndpoint,
      headers: resolvedHeaders,
      requestTimeout: resolvedRequestTimeout,
      payload: payload,
    );
  }

  Stream<ChatUiStreamChunk> _sendPayload({
    required String chatId,
    required _HttpChatTransportResumeState state,
    required Uri endpoint,
    required Map<String, String> headers,
    required Duration? requestTimeout,
    required Map<String, Object?> payload,
  }) async* {
    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: endpoint,
          method: TransportMethod.post,
          headers: {
            ...headers,
          },
          body: payload,
          timeout: requestTimeout,
          responseType: TransportResponseType.plainText,
        ),
      );

      if (response.statusCode >= 400) {
        _clearResumeState(chatId, state);
        yield ChatUiEventChunk(
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
          case HttpChatTransportTransportStartChunk(:final resumeToken):
            if (resumeToken != null) {
              state.resumeToken = resumeToken;
            }
          case HttpChatTransportStartChunk(
              :final resumeToken,
              :final messageId,
            ):
            if (resumeToken != null) {
              state.resumeToken = resumeToken;
            }
            if (messageId != null) {
              final replayChunk = ChatUiMessageStartChunk(
                messageId: messageId,
              );
              state.replayChunks.add(replayChunk);
              yield replayChunk;
            }
          case HttpChatTransportMessageStartChunk(
              :final messageId,
              :final metadata,
            ):
            final replayChunk = ChatUiMessageStartChunk(
              messageId: messageId,
              metadata: metadata,
            );
            state.replayChunks.add(replayChunk);
            yield replayChunk;
          case HttpChatTransportMessageMetadataChunk(:final metadata):
            final replayChunk = ChatUiMessageMetadataChunk(
              metadata: metadata,
            );
            state.replayChunks.add(replayChunk);
            yield replayChunk;
          case HttpChatTransportEventChunk(:final event):
            final replayChunk = ChatUiEventChunk(event);
            state.replayChunks.add(replayChunk);
            if (event is FinishEvent) {
              _clearResumeState(chatId, state);
            }
            yield replayChunk;
          case HttpChatTransportDataPartChunk(:final part):
            final replayChunk = ChatUiDataPartChunk<Object?>(part);
            state.replayChunks.add(replayChunk);
            yield replayChunk;
          case HttpChatTransportAbortChunk(:final reason):
            _clearResumeState(chatId, state);
            yield ChatUiEventChunk(
              AbortEvent(
                reason: reason,
              ),
            );
            yield ChatUiEventChunk(
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
            yield ChatUiEventChunk(
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
          case HttpChatTransportMessageFinishChunk(:final metadata):
            final replayChunk = ChatUiMessageFinishChunk(
              metadata: metadata,
            );
            state.replayChunks.add(replayChunk);
            yield replayChunk;
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
      yield ChatUiEventChunk(
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

  Map<String, String> _baseHeaders() {
    return {
      'content-type': 'application/json',
      'accept': 'text/event-stream',
      ...headers,
    };
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
  final List<ChatUiStreamChunk> replayChunks = [];
  String? resumeToken;
  bool isTerminal = false;

  bool get canReconnect => !isTerminal && resumeToken != null;
}
