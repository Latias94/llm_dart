import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

ChatController createHttpReconnectDemoController({
  String uiSurface = 'flutter',
}) {
  return ChatController(
    session: DefaultChatSession(
      transport: createHttpReconnectDemoTransport(
        uiSurface: uiSurface,
      ),
    ),
  );
}

HttpChatTransport createHttpReconnectDemoTransport({
  String uiSurface = 'flutter',
}) {
  return HttpChatTransport(
    endpoint: Uri.parse('https://backend.example/chat'),
    transport: _InProcessReconnectTransport(),
    prepareSendMessagesRequest: (context) {
      return HttpChatTransportPreparedSendMessagesRequest(
        headers: {
          ...context.headers,
          'x-demo-surface': uiSurface,
        },
        payload: HttpChatTransportRequestPayload(
          chatId: context.payload.chatId,
          prompt: context.payload.prompt,
          generateOptions: context.payload.generateOptions,
          streamProtocol: context.payload.streamProtocol,
          metadata: {
            ...context.payload.metadata,
            'uiSurface': uiSurface,
            'demo': 'http-reconnect',
          },
        ),
      );
    },
    prepareReconnectRequest: (context) {
      return HttpChatTransportPreparedReconnectRequest(
        headers: {
          ...context.headers,
          'x-demo-reconnect': '1',
        },
        payload: HttpChatTransportReconnectRequestPayload(
          chatId: context.payload.chatId,
          resumeToken: context.payload.resumeToken,
          streamProtocol: context.payload.streamProtocol,
          metadata: {
            ...context.payload.metadata,
            'resumeClient': uiSurface,
            'resumeReason': 'network-error',
          },
        ),
      );
    },
  );
}

String reconnectProgressSummary(ChatUiMessage message) {
  final value = _dataPartMap(message, 'progress')?['value'];
  if (value is num) {
    return '${(value * 100).round()}%';
  }

  return '';
}

String reconnectInfoSummary(ChatUiMessage message) {
  final raw = _dataPartMap(message, 'reconnect-info');
  if (raw == null) {
    return '';
  }

  final resumeClient = raw['resumeClient'];
  final reconnectAttempts = raw['reconnectAttempts'];
  if (resumeClient is String && reconnectAttempts is num) {
    return '$resumeClient / attempts=${reconnectAttempts.round()}';
  }

  return '';
}

Map<String, Object?>? _dataPartMap(
  ChatUiMessage message,
  String key,
) {
  final mapped = const ChatMessageMapper().map(message);

  for (final part in mapped.dataParts) {
    if (part.key != key) {
      continue;
    }

    if (part.data is Map<String, Object?>) {
      return part.data as Map<String, Object?>;
    }
    if (part.data is Map) {
      return Map<String, Object?>.from(part.data as Map);
    }
  }

  return null;
}

final class _InProcessReconnectTransport implements TransportClient {
  static const _requestCodec = HttpChatTransportRequestJsonCodec();
  static const _chunkCodec = HttpChatTransportChunkJsonCodec();

  int _sendAttempts = 0;
  int _reconnectAttempts = 0;

  @override
  Future<TransportResponse> send(TransportRequest request) {
    throw UnsupportedError(
      'This reconnect demo only supports streaming chat requests.',
    );
  }

  @override
  Future<StreamingTransportResponse> sendStream(
      TransportRequest request) async {
    final body = request.body;
    if (body is! Map) {
      throw const TransportResponseFormatException(
        'Expected JSON object request body for reconnect demo.',
      );
    }

    final kind = body['kind'];
    if (kind == HttpChatTransportRequestJsonCodec.envelopeKind) {
      final payload = _requestCodec.decodeRequest(body);
      _sendAttempts += 1;

      return StreamingTransportResponse(
        statusCode: 200,
        headers: const {
          'content-type': 'text/event-stream',
        },
        stream: Stream<List<int>>.multi((controller) {
          controller.add(
            _sseFrame(
              _chunkCodec.encodeChunk(
                HttpChatTransportStartChunk(
                  requestId: 'send-$_sendAttempts',
                  messageId: 'assistant-${payload.chatId}',
                  resumeToken: 'resume-1',
                ),
              ),
            ),
          );
          controller.add(
            _sseFrame(
              _chunkCodec.encodeChunk(
                HttpChatTransportMessageMetadataChunk(
                  metadata: const {
                    'phase': 'streaming',
                    'demo': 'http-reconnect',
                  },
                ),
              ),
            ),
          );
          controller.add(
            _sseFrame(
              _chunkCodec.encodeChunk(
                HttpChatTransportEventChunk(
                  StartEvent(
                    warnings: const [
                      ModelWarning(
                        type: ModelWarningType.compatibility,
                        message: 'Demo stream will require reconnect recovery.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          controller.add(
            _sseFrame(
              _chunkCodec.encodeChunk(
                const HttpChatTransportEventChunk(
                  TextStartEvent(id: 'text-1'),
                ),
              ),
            ),
          );
          controller.add(
            _sseFrame(
              _chunkCodec.encodeChunk(
                const HttpChatTransportEventChunk(
                  TextDeltaEvent(
                    id: 'text-1',
                    delta: 'Connection lost after ',
                  ),
                ),
              ),
            ),
          );
          controller.add(
            _sseFrame(
              _chunkCodec.encodeChunk(
                const HttpChatTransportDataPartChunk(
                  DataUiPart<Object?>(
                    id: 'progress',
                    key: 'progress',
                    data: {
                      'value': 0.5,
                    },
                  ),
                ),
              ),
            ),
          );
          controller.add(
            _sseFrame(
              _chunkCodec.encodeChunk(
                const HttpChatTransportCheckpointChunk(
                  resumeToken: 'resume-2',
                ),
              ),
            ),
          );
          controller.addError(
            TransportNetworkException(
              'socket closed during demo stream',
              uri: request.uri,
            ),
          );
        }),
      );
    }

    if (kind == HttpChatTransportRequestJsonCodec.reconnectEnvelopeKind) {
      final payload = _requestCodec.decodeReconnectRequest(body);
      _reconnectAttempts += 1;

      return StreamingTransportResponse(
        statusCode: 200,
        headers: const {
          'content-type': 'text/event-stream',
        },
        stream: Stream<List<int>>.fromIterable([
          _sseFrame(
            _chunkCodec.encodeChunk(
              HttpChatTransportStartChunk(
                requestId: 'reconnect-$_reconnectAttempts',
                resumeToken: 'resume-3',
              ),
            ),
          ),
          _sseFrame(
            _chunkCodec.encodeChunk(
              const HttpChatTransportDataPartChunk(
                DataUiPart<Object?>(
                  id: 'progress',
                  key: 'progress',
                  data: {
                    'value': 1.0,
                  },
                ),
              ),
            ),
          ),
          _sseFrame(
            _chunkCodec.encodeChunk(
              HttpChatTransportDataPartChunk(
                DataUiPart<Object?>(
                  id: 'reconnect-info',
                  key: 'reconnect-info',
                  data: {
                    'resumeClient': payload.metadata['resumeClient'],
                    'resumeReason': payload.metadata['resumeReason'],
                    'reconnectAttempts': _reconnectAttempts,
                    'resumeToken': payload.resumeToken,
                  },
                ),
              ),
            ),
          ),
          _sseFrame(
            _chunkCodec.encodeChunk(
              const HttpChatTransportEventChunk(
                TextDeltaEvent(
                  id: 'text-1',
                  delta: 'resume succeeds.',
                ),
              ),
            ),
          ),
          _sseFrame(
            _chunkCodec.encodeChunk(
              const HttpChatTransportEventChunk(
                TextEndEvent(id: 'text-1'),
              ),
            ),
          ),
          _sseFrame(
            _chunkCodec.encodeChunk(
              HttpChatTransportMessageFinishChunk(
                metadata: {
                  'recovered': true,
                  'resumeAttempts': _reconnectAttempts,
                },
              ),
            ),
          ),
          _sseFrame(
            _chunkCodec.encodeChunk(
              const HttpChatTransportEventChunk(
                FinishEvent(
                  finishReason: FinishReason.stop,
                ),
              ),
            ),
          ),
          _sseFrame(
            _chunkCodec.encodeChunk(
              const HttpChatTransportFinishChunk(),
            ),
          ),
        ]),
      );
    }

    throw const TransportResponseFormatException(
      'Unsupported reconnect demo envelope kind.',
    );
  }

  List<int> _sseFrame(Map<String, Object?> payload) {
    return utf8.encode('data: ${jsonEncode(payload)}\n\n');
  }
}
