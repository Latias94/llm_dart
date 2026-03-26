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

  const HttpChatTransport({
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

    final payload = requestCodec.encodeRequest(
      HttpChatTransportRequestPayload(
        chatId: request.chatId,
        prompt: request.prompt,
        generateOptions: request.options.generateOptions,
      ),
    );

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
          case HttpChatTransportEventChunk(:final event):
            yield event;
          case HttpChatTransportAbortChunk(:final reason):
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
            yield ErrorEvent({
              'type': 'http-chat-transport-error',
              if (code != null) 'code': code,
              'message': message,
              if (details != null) 'details': details,
            });
            return;
          case HttpChatTransportStartChunk():
          case HttpChatTransportCheckpointChunk():
          case HttpChatTransportFinishChunk():
          case HttpChatTransportKeepAliveChunk():
            break;
        }
      }
    } catch (error) {
      yield ErrorEvent(error);
    }
  }

  @override
  Stream<TextStreamEvent>? reconnect(String chatId) => null;

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
}
