import 'dart:convert';

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
  Stream<TextStreamEvent> sendMessages(ChatTransportRequest request) async* {
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
  Stream<TextStreamEvent>? reconnect(String chatId) {
    final state = _resumeStates[chatId];
    final resumeToken = state?.resumeToken;
    if (state == null || resumeToken == null) {
      return null;
    }

    final replayEvents = List<TextStreamEvent>.of(state.replayEvents);
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
      replayEvents: replayEvents,
    );
  }

  Stream<TextStreamEvent> _reconnectWithReplay({
    required String chatId,
    required _HttpChatTransportResumeState state,
    required Map<String, Object?> payload,
    required List<TextStreamEvent> replayEvents,
  }) async* {
    yield* Stream<TextStreamEvent>.fromIterable(replayEvents);
    yield* _sendPayload(
      chatId: chatId,
      state: state,
      payload: payload,
    );
  }

  Stream<TextStreamEvent> _sendPayload({
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
        yield ErrorEvent({
          'type': 'http-transport-error',
          'statusCode': response.statusCode,
        });
        return;
      }

      final chunks = utf8.decoder.bind(response.stream);
      await for (final frame in sseDecoder.decode(chunks)) {
        if (frame.data.isEmpty) {
          continue;
        }

        final chunk = chunkCodec.decodeChunk(_decodeJson(frame.data));
        switch (chunk) {
          case HttpChatTransportStartChunk(:final resumeToken):
            if (resumeToken != null) {
              state.resumeToken = resumeToken;
            }
          case HttpChatTransportEventChunk(:final event):
            state.replayEvents.add(event);
            if (event is FinishEvent) {
              _clearResumeState(chatId, state);
            }
            yield event;
          case HttpChatTransportAbortChunk(:final reason):
            _clearResumeState(chatId, state);
            yield FinishEvent(
              finishReason: FinishReason.aborted,
              rawFinishReason: reason,
            );
            return;
          case HttpChatTransportErrorChunk(
              :final code,
              :final message,
              :final details,
            ):
            _clearResumeState(chatId, state);
            yield ErrorEvent({
              'type': 'http-chat-transport-error',
              if (code != null) 'code': code,
              'message': message,
              if (details != null) 'details': details,
            });
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
      yield ErrorEvent(error);
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

  Map<String, Object?> _decodeJson(String data) {
    final decoded = jsonDecode(data);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }

    throw FormatException(
      'Expected a JSON object SSE payload but received ${decoded.runtimeType}.',
    );
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
  final List<TextStreamEvent> replayEvents = [];
  String? resumeToken;
  bool isTerminal = false;

  bool get canReconnect => !isTerminal && resumeToken != null;
}
