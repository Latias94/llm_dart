import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
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

      final chunks = await transport
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

      final events = _eventsFromChunks(chunks);
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

      final chunks = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      final finish = _singleEvent(chunks) as FinishEvent;
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

      final chunks = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      final error = _singleEvent(chunks) as ErrorEvent;
      expect(error.error.kind, ModelErrorKind.transport);
      expect(error.error.code, 'transport_error');
      expect(error.error.message, 'backend failed');
      expect(
        error.error.details,
        {
          'retryable': false,
        },
      );
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

      final firstAttemptChunks = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      final firstAttemptEvents = _eventsFromChunks(firstAttemptChunks);
      expect(firstAttemptEvents, hasLength(4));
      expect(firstAttemptEvents[0], isA<StartEvent>());
      expect(firstAttemptEvents[1], isA<TextStartEvent>());
      expect((firstAttemptEvents[2] as TextDeltaEvent).delta, 'Hel');
      expect(firstAttemptEvents[3], isA<ErrorEvent>());

      final resumedStream = transport.reconnect('chat-1');
      expect(resumedStream, isNotNull);

      final resumedChunks = await resumedStream!.toList();
      final resumedEvents = _eventsFromChunks(resumedChunks);
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

    test('reconnect replays buffered data-part chunks', () async {
      const chunkCodec = HttpChatTransportChunkJsonCodec();
      var attempt = 0;

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
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
                        const HttpChatTransportDataPartChunk(
                          DataUiPart<Object?>(
                            id: 'progress',
                            key: 'status',
                            data: {
                              'value': 0.25,
                            },
                          ),
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
                        resumeToken: 'resume-2',
                      ),
                    ),
                  ),
                  _sseFrame(
                    chunkCodec.encodeChunk(
                      const HttpChatTransportDataPartChunk(
                        DataUiPart<Object?>(
                          id: 'progress',
                          key: 'status',
                          data: {
                            'value': 1.0,
                          },
                        ),
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

      final firstAttemptChunks = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      expect(firstAttemptChunks, hasLength(2));
      expect(firstAttemptChunks[0], isA<ChatTransportDataPartChunk>());
      expect(firstAttemptChunks[1], isA<ChatTransportEventChunk>());
      expect(
        ((firstAttemptChunks[1] as ChatTransportEventChunk).event as ErrorEvent)
            .error,
        allOf(
          isA<ModelError>(),
          predicate<ModelError>(
            (error) =>
                error.kind == ModelErrorKind.transport &&
                error.originalType == 'StateError' &&
                error.message.contains('socket closed'),
          ),
        ),
      );

      final resumedChunks = await transport.reconnect('chat-1')!.toList();
      expect(resumedChunks, hasLength(3));
      expect(resumedChunks[0], isA<ChatTransportDataPartChunk>());
      expect(
        (((resumedChunks[0] as ChatTransportDataPartChunk).part.data
            as Map<String, Object?>)['value']),
        0.25,
      );
      expect(resumedChunks[1], isA<ChatTransportDataPartChunk>());
      expect(
        (((resumedChunks[1] as ChatTransportDataPartChunk).part.data
            as Map<String, Object?>)['value']),
        1.0,
      );
      expect(
        (_singleEvent([resumedChunks[2]]) as FinishEvent).finishReason,
        FinishReason.stop,
      );
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

      final chunks = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();

      expect(_singleEvent(chunks), isA<FinishEvent>());
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

List<TextStreamEvent> _eventsFromChunks(List<ChatTransportChunk> chunks) {
  return chunks
      .whereType<ChatTransportEventChunk>()
      .map((chunk) => chunk.event)
      .toList(growable: false);
}

TextStreamEvent _singleEvent(List<ChatTransportChunk> chunks) {
  final events = _eventsFromChunks(chunks);
  expect(events, hasLength(1));
  return events.single;
}

typedef _FakeTransportClient = FakeTransportClient;
