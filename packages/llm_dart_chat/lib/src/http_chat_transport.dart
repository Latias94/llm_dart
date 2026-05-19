import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'chat_transport.dart';
import 'http_chat_transport_chunk_json_codec.dart';
import 'http_chat_transport_request_json_codec.dart';
import 'http_chat_transport_request_payload.dart';
import 'http_chat_transport_request_support.dart';
import 'http_chat_transport_resume_state.dart';
import 'http_chat_transport_stream_projection.dart';
import 'http_chat_transport_stream_protocol.dart';

export 'http_chat_transport_request_support.dart'
    show
        HttpChatTransportPreparedReconnectRequest,
        HttpChatTransportPreparedSendMessagesRequest,
        HttpChatTransportProviderOptionsEncoder,
        HttpChatTransportReconnectRequestContext,
        HttpChatTransportSendMessagesRequestContext,
        PrepareReconnectRequest,
        PrepareSendMessagesRequest;

final class HttpChatTransport implements ChatTransport {
  final Uri endpoint;
  final TransportClient transport;
  final SseDecoder sseDecoder;
  final HttpChatTransportRequestJsonCodec requestCodec;
  final HttpChatTransportChunkJsonCodec chunkCodec;
  final HttpChatTransportStreamProtocol streamProtocol;
  final Map<String, String> headers;
  final Duration? requestTimeout;
  final HttpChatTransportProviderOptionsEncoder? providerOptionsEncoder;
  final PrepareSendMessagesRequest? prepareSendMessagesRequest;
  final PrepareReconnectRequest? prepareReconnectRequest;
  final Map<String, HttpChatTransportResumeState> _resumeStates = {};

  HttpChatTransport({
    required this.endpoint,
    required this.transport,
    this.sseDecoder = const DefaultSseDecoder(),
    this.requestCodec = const HttpChatTransportRequestJsonCodec(),
    this.chunkCodec = const HttpChatTransportChunkJsonCodec(),
    this.streamProtocol = HttpChatTransportStreamProtocol.uiMessageStreamV2,
    this.headers = const {},
    this.requestTimeout,
    this.providerOptionsEncoder,
    this.prepareSendMessagesRequest,
    this.prepareReconnectRequest,
  });

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) async* {
    validateSerializableHttpChatRequestOptions(request.options);

    final callOptionsPayload = serializeHttpChatTransportCallOptions(
      request.options.callOptions,
      providerOptionsEncoder: providerOptionsEncoder,
    );
    final baseRequestTimeout =
        request.options.callOptions.timeout ?? requestTimeout;
    final state = HttpChatTransportResumeState(
      callOptionsPayload: callOptionsPayload,
      requestTimeout: baseRequestTimeout,
      maxRetries: request.options.callOptions.maxRetries,
      cancellation: request.options.callOptions.cancellation,
    );
    _resumeStates[request.chatId] = state;

    final baseHeaders = buildHttpChatTransportBaseHeaders(headers);
    final basePayload = HttpChatTransportRequestPayload(
      chatId: request.chatId,
      prompt: request.prompt,
      generateOptions: request.options.generateOptions,
      callOptions: callOptionsPayload,
      streamProtocol: streamProtocol,
      metadata: request.options.metadata,
    );
    final preparedRequest = await prepareSendMessagesRequest?.call(
      HttpChatTransportSendMessagesRequestContext(
        request: request,
        endpoint: endpoint,
        headers: Map.unmodifiable(baseHeaders),
        requestTimeout: baseRequestTimeout,
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
            : baseRequestTimeout;

    yield* _sendPayload(
      chatId: request.chatId,
      state: state,
      endpoint: resolvedEndpoint,
      headers: resolvedHeaders,
      requestTimeout: resolvedRequestTimeout,
      maxRetries: state.maxRetries,
      cancellation: state.cancellation,
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
    required HttpChatTransportResumeState state,
    required List<ChatUiStreamChunk> replayChunks,
  }) async* {
    final baseHeaders = buildHttpChatTransportBaseHeaders(headers);
    final basePayload = HttpChatTransportReconnectRequestPayload(
      chatId: chatId,
      resumeToken: resumeToken,
      callOptions: state.callOptionsPayload,
      streamProtocol: streamProtocol,
    );
    final preparedRequest = await prepareReconnectRequest?.call(
      HttpChatTransportReconnectRequestContext(
        chatId: chatId,
        resumeToken: resumeToken,
        endpoint: endpoint,
        headers: Map.unmodifiable(baseHeaders),
        requestTimeout: state.requestTimeout,
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
            : state.requestTimeout;

    yield* Stream<ChatUiStreamChunk>.fromIterable(replayChunks);
    yield* _sendPayload(
      chatId: chatId,
      state: state,
      endpoint: resolvedEndpoint,
      headers: resolvedHeaders,
      requestTimeout: resolvedRequestTimeout,
      maxRetries: state.maxRetries,
      cancellation: state.cancellation,
      payload: payload,
    );
  }

  Stream<ChatUiStreamChunk> _sendPayload({
    required String chatId,
    required HttpChatTransportResumeState state,
    required Uri endpoint,
    required Map<String, String> headers,
    required Duration? requestTimeout,
    required int? maxRetries,
    required ProviderCancellation? cancellation,
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
          maxRetries: maxRetries,
          cancellation: cancellation,
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
        final projected = projectHttpChatTransportChunk(
          chunk: chunk,
          state: state,
          clearResumeState: () => _clearResumeState(chatId, state),
        );

        switch (projected) {
          case HttpChatTransportEmitChunk(
              :final chunks,
              :final terminateStream,
            ):
            yield* Stream<ChatUiStreamChunk>.fromIterable(chunks);
            if (terminateStream) {
              return;
            }
          case HttpChatTransportNoopChunk():
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

  void _clearResumeState(
    String chatId,
    HttpChatTransportResumeState state,
  ) {
    if (identical(_resumeStates[chatId], state)) {
      _resumeStates.remove(chatId);
    }
    state.markTerminal();
  }
}
