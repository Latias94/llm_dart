import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransport', () {
    test('encodes requests and forwards event chunks', () async {
      TransportRequest? capturedRequest;
      const chunkCodec = HttpChatTransportChunkJsonCodec();

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportStartChunk(
                      requestId: 'req-1',
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportEventChunk(
                      TextStartEvent(id: 'text-1'),
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportEventChunk(
                      TextDeltaEvent(
                        id: 'text-1',
                        delta: 'Hello',
                      ),
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportCheckpointChunk(
                      resumeToken: 'resume-1',
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportEventChunk(
                      FinishEvent(
                        finishReason: FinishReason.stop,
                      ),
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportFinishChunk(),
                  ),
                ),
              ]),
            );
          },
        ),
      );

      final events = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: const ChatRequestOptions(
                generateOptions: GenerateTextOptions(
                  temperature: 0.2,
                ),
              ),
            ),
          )
          .toList();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri, Uri.parse('https://example.com/chat'));
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.plainText);

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(body['kind'], HttpChatTransportRequestJsonCodec.envelopeKind);

      expect(events, hasLength(3));
      expect(events[0], isA<TextStartEvent>());
      expect((events[1] as TextDeltaEvent).delta, 'Hello');
      expect((events[2] as FinishEvent).finishReason, FinishReason.stop);
    });

    test('maps abort chunk to aborted finish event', () async {
      const chunkCodec = HttpChatTransportChunkJsonCodec();

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportAbortChunk(
                      reason: 'cancelled',
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      );

      final events = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      final finish = events.single as FinishEvent;
      expect(finish.finishReason, FinishReason.aborted);
      expect(finish.rawFinishReason, 'cancelled');
    });

    test('maps transport error chunks to ErrorEvent', () async {
      const chunkCodec = HttpChatTransportChunkJsonCodec();

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportErrorChunk(
                      message: 'backend failed',
                      code: 'transport_error',
                      details: {
                        'retryable': false,
                      },
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      );

      final events = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      final error = events.single as ErrorEvent;
      expect(error.error, {
        'type': 'http-chat-transport-error',
        'code': 'transport_error',
        'message': 'backend failed',
        'details': {
          'retryable': false,
        },
      });
    });

    test('reconnect replays buffered events and sends reconnect payload',
        () async {
      final capturedRequests = <TransportRequest>[];
      const requestCodec = HttpChatTransportRequestJsonCodec();
      const chunkCodec = HttpChatTransportChunkJsonCodec();
      var attempt = 0;

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        requestCodec: requestCodec,
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequests.add(request);
            attempt += 1;

            if (attempt == 1) {
              return StreamingTransportResponse(
                statusCode: 200,
                stream: Stream<List<int>>.multi((controller) {
                  controller.add(
                    _sseFrame(
                      chunkCodec.encodeChunk(
                        const HttpChatTransportStartChunk(
                          resumeToken: 'resume-1',
                        ),
                      ),
                    ),
                  );
                  controller.add(
                    _sseFrame(
                      chunkCodec.encodeChunk(
                        HttpChatTransportEventChunk(StartEvent()),
                      ),
                    ),
                  );
                  controller.add(
                    _sseFrame(
                      chunkCodec.encodeChunk(
                        const HttpChatTransportEventChunk(
                          TextStartEvent(id: 'text-1'),
                        ),
                      ),
                    ),
                  );
                  controller.add(
                    _sseFrame(
                      chunkCodec.encodeChunk(
                        const HttpChatTransportEventChunk(
                          TextDeltaEvent(
                            id: 'text-1',
                            delta: 'Hel',
                          ),
                        ),
                      ),
                    ),
                  );
                  controller.add(
                    _sseFrame(
                      chunkCodec.encodeChunk(
                        const HttpChatTransportCheckpointChunk(
                          resumeToken: 'resume-2',
                        ),
                      ),
                    ),
                  );
                  controller.addError(StateError('socket closed'));
                }),
              );
            }

            if (attempt == 2) {
              return StreamingTransportResponse(
                statusCode: 200,
                stream: Stream.fromIterable([
                  _sseFrame(
                    chunkCodec.encodeChunk(
                      const HttpChatTransportStartChunk(
                        resumeToken: 'resume-3',
                      ),
                    ),
                  ),
                  _sseFrame(
                    chunkCodec.encodeChunk(
                      const HttpChatTransportEventChunk(
                        TextDeltaEvent(
                          id: 'text-1',
                          delta: 'lo',
                        ),
                      ),
                    ),
                  ),
                  _sseFrame(
                    chunkCodec.encodeChunk(
                      const HttpChatTransportEventChunk(
                        TextEndEvent(id: 'text-1'),
                      ),
                    ),
                  ),
                  _sseFrame(
                    chunkCodec.encodeChunk(
                      const HttpChatTransportEventChunk(
                        FinishEvent(
                          finishReason: FinishReason.stop,
                        ),
                      ),
                    ),
                  ),
                  _sseFrame(
                    chunkCodec.encodeChunk(
                      const HttpChatTransportFinishChunk(),
                    ),
                  ),
                ]),
              );
            }

            throw StateError('Unexpected transport attempt $attempt');
          },
        ),
      );

      final firstAttemptEvents = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      expect(firstAttemptEvents, hasLength(4));
      expect(firstAttemptEvents[0], isA<StartEvent>());
      expect(firstAttemptEvents[1], isA<TextStartEvent>());
      expect((firstAttemptEvents[2] as TextDeltaEvent).delta, 'Hel');
      expect(firstAttemptEvents[3], isA<ErrorEvent>());

      final resumedStream = transport.reconnect('chat-1');
      expect(resumedStream, isNotNull);

      final resumedEvents = await resumedStream!.toList();
      expect(resumedEvents, hasLength(6));
      expect(resumedEvents[0], isA<StartEvent>());
      expect(resumedEvents[1], isA<TextStartEvent>());
      expect((resumedEvents[2] as TextDeltaEvent).delta, 'Hel');
      expect((resumedEvents[3] as TextDeltaEvent).delta, 'lo');
      expect(resumedEvents[4], isA<TextEndEvent>());
      expect(
        (resumedEvents[5] as FinishEvent).finishReason,
        FinishReason.stop,
      );

      expect(capturedRequests, hasLength(2));
      final reconnectRequest = requestCodec.decodeReconnectRequest(
        capturedRequests[1].body,
      );
      expect(reconnectRequest.chatId, 'chat-1');
      expect(reconnectRequest.resumeToken, 'resume-2');

      expect(transport.reconnect('chat-1'), isNull);
    });

    test('clears reconnect state after a successful terminal finish', () async {
      const chunkCodec = HttpChatTransportChunkJsonCodec();

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportStartChunk(
                      resumeToken: 'resume-1',
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportEventChunk(
                      FinishEvent(
                        finishReason: FinishReason.stop,
                      ),
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    const HttpChatTransportFinishChunk(),
                  ),
                ),
              ]),
            );
          },
        ),
      );

      final events = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      expect(events.single, isA<FinishEvent>());
      expect(transport.reconnect('chat-1'), isNull);
    });

    test('rejects unsupported call options for remote transport', () async {
      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: const _FakeTransportClient(),
      );

      expect(
        transport.sendMessages(
          ChatTransportRequest(
            chatId: 'chat-1',
            prompt: [
              UserPromptMessage.text('Hello'),
            ],
            options: const ChatRequestOptions(
              callOptions: CallOptions(
                timeout: Duration(seconds: 5),
              ),
            ),
          ),
        ),
        emitsError(isA<UnsupportedError>()),
      );
    });
  });
}

List<int> _sseFrame(Map<String, Object?> payload) {
  return utf8.encode('data: ${jsonEncode(payload)}\n\n');
}

final class _FakeTransportClient implements TransportClient {
  final Future<StreamingTransportResponse> Function(TransportRequest request)?
      onSendStream;

  const _FakeTransportClient({
    this.onSendStream,
  });

  @override
  Future<TransportResponse> send(TransportRequest request) {
    throw UnimplementedError('send() was not configured for this test.');
  }

  @override
  Future<StreamingTransportResponse> sendStream(TransportRequest request) {
    if (onSendStream == null) {
      throw UnimplementedError(
        'sendStream() was not configured for this test.',
      );
    }

    return onSendStream!(request);
  }
}
