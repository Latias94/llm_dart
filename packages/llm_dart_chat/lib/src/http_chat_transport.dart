import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'chat_transport.dart';
import 'http_chat_transport_chunk_json_codec.dart';
import 'http_chat_transport_request_json_codec.dart';
import 'http_chat_transport_request_preparer.dart';
import 'http_chat_transport_request_support.dart';
import 'http_chat_transport_resume_state.dart';
import 'http_chat_transport_stream_client.dart';
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
  late final HttpChatTransportStreamClient _streamClient;
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
  }) {
    _streamClient = HttpChatTransportStreamClient(
      transport: transport,
      sseDecoder: sseDecoder,
      chunkCodec: chunkCodec,
    );
  }

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) async* {
    final requestPreparer = _requestPreparer();
    final state = requestPreparer.createSendMessagesState(request);
    _resumeStates[request.chatId] = state;

    final prepared = await requestPreparer.prepareSendMessages(
      request: request,
      state: state,
    );
    yield* _sendPayloadRequest(
      state: state,
      prepared: prepared,
    );
  }

  HttpChatTransportRequestPreparer _requestPreparer() {
    return HttpChatTransportRequestPreparer(
      endpoint: endpoint,
      headers: headers,
      requestTimeout: requestTimeout,
      requestCodec: requestCodec,
      streamProtocol: streamProtocol,
      providerOptionsEncoder: providerOptionsEncoder,
      prepareSendMessagesRequest: prepareSendMessagesRequest,
      prepareReconnectRequest: prepareReconnectRequest,
    );
  }

  Stream<ChatUiStreamChunk> _sendPayloadRequest({
    required HttpChatTransportResumeState state,
    required HttpChatTransportPreparedPayloadRequest prepared,
  }) {
    return _sendPayload(
      state: state,
      endpoint: prepared.endpoint,
      headers: prepared.headers,
      requestTimeout: prepared.requestTimeout,
      maxRetries: prepared.maxRetries,
      cancellation: prepared.cancellation,
      payload: prepared.payload,
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
    final prepared = await _requestPreparer().prepareReconnect(
      chatId: chatId,
      resumeToken: resumeToken,
      state: state,
    );

    yield* Stream<ChatUiStreamChunk>.fromIterable(replayChunks);
    yield* _sendPayloadRequest(
      state: state,
      prepared: prepared,
    );
  }

  Stream<ChatUiStreamChunk> _sendPayload({
    required HttpChatTransportResumeState state,
    required Uri endpoint,
    required Map<String, String> headers,
    required Duration? requestTimeout,
    required int? maxRetries,
    required ProviderCancellation? cancellation,
    required Map<String, Object?> payload,
  }) async* {
    yield* _streamClient.sendPayload(
      state: state,
      endpoint: endpoint,
      headers: headers,
      requestTimeout: requestTimeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      payload: payload,
      clearResumeState: () => _clearResumeStateForState(state),
    );
  }

  void _clearResumeStateForState(HttpChatTransportResumeState state) {
    for (final entry in _resumeStates.entries.toList(growable: false)) {
      if (identical(entry.value, state)) {
        _clearResumeState(entry.key, state);
        return;
      }
    }
    state.markTerminal();
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
