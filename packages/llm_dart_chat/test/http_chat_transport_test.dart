import 'dart:convert';

import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
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
                    const HttpChatTransportTransportStartChunk(
                      requestId: 'req-1',
                      resumeToken: 'resume-1',
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    HttpChatTransportMessageStartChunk(
                      messageId: 'server-msg-1',
                      metadata: const {
                        'serverOwned': true,
                      },
                    ),
                  ),
                ),
                _sseFrame(
                  chunkCodec.encodeChunk(
                    HttpChatTransportMessageMetadataChunk(
                      metadata: const {
                        'phase': 'streaming',
                      },
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
                    HttpChatTransportMessageFinishChunk(
                      metadata: const {
                        'persisted': true,
                      },
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
                metadata: {
                  'clientRequestId': 'req-client-1',
                },
              ),
            ),
          )
          .toList();

      final startChunk = chunks.first as ChatUiMessageStartChunk;
      expect(startChunk.messageId, 'server-msg-1');
      expect(startChunk.metadata['serverOwned'], isTrue);

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri, Uri.parse('https://example.com/chat'));
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.plainText);

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(body['kind'], HttpChatTransportRequestJsonCodec.envelopeKind);
      final decodedRequest =
          const HttpChatTransportRequestJsonCodec().decodeRequest(body);
      expect(
        decodedRequest.streamProtocol,
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
      );
      expect(
        decodedRequest.metadata,
        {
          'clientRequestId': 'req-client-1',
        },
      );

      final metadataChunk = chunks[1] as ChatUiMessageMetadataChunk;
      expect(metadataChunk.metadata['phase'], 'streaming');

      final events = _eventsFromChunks(chunks);
      expect(events, hasLength(3));
      expect(events[0], isA<TextStartEvent>());
      expect((events[1] as TextDeltaEvent).delta, 'Hello');
      expect((events[2] as FinishEvent).finishReason, FinishReason.stop);

      final finishChunk = chunks.last as ChatUiMessageFinishChunk;
      expect(finishChunk.metadata['persisted'], isTrue);
    });

    test('serializes supported call options and applies transport controls',
        () async {
      TransportRequest? capturedRequest;
      final cancellation = ProviderCancellation();

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              stream: const Stream<List<int>>.empty(),
            );
          },
        ),
      );

      await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: ChatRequestOptions(
                callOptions: CallOptions(
                  timeout: const Duration(seconds: 5),
                  headers: const {
                    'x-provider-trace': 'trace-1',
                  },
                  maxRetries: 2,
                  cancellation: cancellation,
                ),
              ),
            ),
          )
          .toList();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(capturedRequest!.maxRetries, 2);
      expect(capturedRequest!.cancellation, same(cancellation));
      expect(capturedRequest!.headers, isNot(contains('x-provider-trace')));

      final decodedRequest =
          const HttpChatTransportRequestJsonCodec().decodeRequest(
        capturedRequest!.body,
      );
      expect(decodedRequest.callOptions.timeout, const Duration(seconds: 5));
      expect(decodedRequest.callOptions.headers, {
        'x-provider-trace': 'trace-1',
      });
      expect(decodedRequest.callOptions.maxRetries, 2);
    });

    test('serializes provider options through an explicit encoder', () async {
      TransportRequest? capturedRequest;
      final providerOptions = _TestProviderOptions('high');

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        providerOptionsEncoder: (options) {
          expect(options, same(providerOptions));
          return {
            'reasoningEffort': providerOptions.reasoningEffort,
          };
        },
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              stream: const Stream<List<int>>.empty(),
            );
          },
        ),
      );

      await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: ChatRequestOptions(
                callOptions: CallOptions(
                  providerOptions: providerOptions,
                ),
              ),
            ),
          )
          .toList();

      final decodedRequest =
          const HttpChatTransportRequestJsonCodec().decodeRequest(
        capturedRequest!.body,
      );
      expect(decodedRequest.callOptions.providerOptions, {
        'reasoningEffort': 'high',
      });
    });

    test(
        'prepareSendMessagesRequest can override endpoint, headers, timeout, and payload',
        () async {
      TransportRequest? capturedRequest;

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        requestTimeout: const Duration(seconds: 3),
        prepareSendMessagesRequest: (context) {
          expect(context.request.trigger, ChatTransportTrigger.regenerate);
          expect(context.payload.metadata['clientRequestId'], 'client-1');
          expect(context.headers['accept'], 'text/event-stream');

          return HttpChatTransportPreparedSendMessagesRequest(
            endpoint: Uri.parse('https://example.com/chat/prepared'),
            headers: {
              ...context.headers,
              'x-custom': '1',
            },
            requestTimeout: const Duration(seconds: 9),
            overrideRequestTimeout: true,
            payload: HttpChatTransportRequestPayload(
              chatId: context.payload.chatId,
              prompt: context.payload.prompt,
              generateOptions: const GenerateTextOptions(
                maxOutputTokens: 128,
              ),
              streamProtocol: context.payload.streamProtocol,
              metadata: {
                ...context.payload.metadata,
                'prepared': true,
              },
            ),
          );
        },
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              stream: const Stream<List<int>>.empty(),
            );
          },
        ),
      );

      await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              trigger: ChatTransportTrigger.regenerate,
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: const ChatRequestOptions(
                metadata: {
                  'clientRequestId': 'client-1',
                },
              ),
            ),
          )
          .toList();

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri,
        Uri.parse('https://example.com/chat/prepared'),
      );
      expect(capturedRequest!.headers['x-custom'], '1');
      expect(capturedRequest!.timeout, const Duration(seconds: 9));

      final decodedRequest =
          const HttpChatTransportRequestJsonCodec().decodeRequest(
        capturedRequest!.body,
      );
      expect(decodedRequest.generateOptions.maxOutputTokens, 128);
      expect(
        decodedRequest.metadata,
        {
          'clientRequestId': 'client-1',
          'prepared': true,
        },
      );
    });

    test('maps abort chunk to abort plus aborted finish events', () async {
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

      final events = _eventsFromChunks(chunks);
      expect(events, hasLength(2));

      final abort = events.first as AbortEvent;
      expect(abort.reason, 'cancelled');

      final finish = events.last as FinishEvent;
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
              options: const ChatRequestOptions(
                callOptions: CallOptions(
                  timeout: Duration(seconds: 6),
                  maxRetries: 1,
                ),
              ),
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
      expect(capturedRequests[1].timeout, const Duration(seconds: 6));
      expect(capturedRequests[1].maxRetries, 1);
      expect(reconnectRequest.chatId, 'chat-1');
      expect(reconnectRequest.resumeToken, 'resume-2');
      expect(reconnectRequest.callOptions.timeout, const Duration(seconds: 6));
      expect(reconnectRequest.callOptions.maxRetries, 1);
      expect(
        reconnectRequest.streamProtocol,
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
      );

      expect(transport.reconnect('chat-1'), isNull);
    });

    test(
        'prepareReconnectRequest can override endpoint, headers, timeout, and payload',
        () async {
      final capturedRequests = <TransportRequest>[];
      const chunkCodec = HttpChatTransportChunkJsonCodec();
      const requestCodec = HttpChatTransportRequestJsonCodec();
      var attempt = 0;

      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        requestTimeout: const Duration(seconds: 4),
        prepareReconnectRequest: (context) {
          expect(context.chatId, 'chat-1');
          expect(context.resumeToken, 'resume-1');
          expect(context.headers['accept'], 'text/event-stream');

          return HttpChatTransportPreparedReconnectRequest(
            endpoint: Uri.parse('https://example.com/chat/reconnect'),
            headers: {
              ...context.headers,
              'x-reconnect': '1',
            },
            requestTimeout: const Duration(seconds: 11),
            overrideRequestTimeout: true,
            payload: HttpChatTransportReconnectRequestPayload(
              chatId: context.payload.chatId,
              resumeToken: context.payload.resumeToken,
              streamProtocol: context.payload.streamProtocol,
              metadata: const {
                'resumeClient': 'mobile',
              },
            ),
          );
        },
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

      await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
            ),
          )
          .toList();
      await transport.reconnect('chat-1')!.toList();

      expect(capturedRequests, hasLength(2));
      final reconnectRequest = capturedRequests[1];
      expect(
        reconnectRequest.uri,
        Uri.parse('https://example.com/chat/reconnect'),
      );
      expect(reconnectRequest.headers['x-reconnect'], '1');
      expect(reconnectRequest.timeout, const Duration(seconds: 11));

      final decodedReconnect = requestCodec.decodeReconnectRequest(
        reconnectRequest.body,
      );
      expect(
        decodedReconnect.metadata,
        {
          'resumeClient': 'mobile',
        },
      );
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
      expect(firstAttemptChunks[0], isA<ChatUiDataPartChunk<Object?>>());
      expect(firstAttemptChunks[1], isA<ChatUiEventChunk>());
      expect(
        ((firstAttemptChunks[1] as ChatUiEventChunk).event as ErrorEvent).error,
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
      expect(resumedChunks[0], isA<ChatUiDataPartChunk<Object?>>());
      expect(
        (((resumedChunks[0] as ChatUiDataPartChunk<Object?>).part.data
            as Map<String, Object?>)['value']),
        0.25,
      );
      expect(resumedChunks[1], isA<ChatUiDataPartChunk<Object?>>());
      expect(
        (((resumedChunks[1] as ChatUiDataPartChunk<Object?>).part.data
            as Map<String, Object?>)['value']),
        1.0,
      );
      expect(
        (_singleEvent([resumedChunks[2]]) as FinishEvent).finishReason,
        FinishReason.stop,
      );
    });

    test('transient data chunks are delivered but not replayed on reconnect',
        () async {
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
                        const HttpChatTransportTransientDataPartChunk(
                          DataUiPart<Object?>(
                            id: 'heartbeat',
                            key: 'tool-status',
                            data: {
                              'phase': 'running',
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

      expect(
          firstAttemptChunks[0], isA<ChatUiTransientDataPartChunk<Object?>>());
      expect(firstAttemptChunks[1], isA<ChatUiEventChunk>());

      final resumedChunks = await transport.reconnect('chat-1')!.toList();
      expect(resumedChunks, hasLength(1));
      expect(
        (_singleEvent(resumedChunks) as FinishEvent).finishReason,
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

    test('rejects provider options without an explicit encoder', () async {
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
            options: ChatRequestOptions(
              callOptions: CallOptions(
                providerOptions: _TestProviderOptions('high'),
              ),
            ),
          ),
        ),
        emitsError(isA<UnsupportedError>()),
      );
    });

    test('serializes tools and tool choice in request payload', () async {
      TransportRequest? capturedRequest;
      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              stream: const Stream<List<int>>.empty(),
            );
          },
        ),
      );

      await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: ChatRequestOptions(
                tools: [
                  FunctionToolDefinition(
                    name: 'weather',
                    inputSchema: ToolJsonSchema.object(),
                  ),
                ],
                toolChoice: const RequiredToolChoice(),
              ),
            ),
          )
          .toList();

      final decodedRequest =
          const HttpChatTransportRequestJsonCodec().decodeRequest(
        capturedRequest!.body,
      );
      expect(decodedRequest.tools.single.name, 'weather');
      expect(decodedRequest.toolChoice, isA<RequiredToolChoice>());
    });

    test('rejects local runtime tool loop options', () async {
      final transport = HttpChatTransport(
        endpoint: Uri.parse('https://example.com/chat'),
        transport: const _FakeTransportClient(),
      );

      await expectLater(
        transport.sendMessages(
          ChatTransportRequest(
            chatId: 'chat-1',
            prompt: [
              UserPromptMessage.text('Hello'),
            ],
            options: ChatRequestOptions(
              functionToolExecutor: (_) =>
                  const GenerateTextToolExecutionResult.output(null),
            ),
          ),
        ),
        emitsError(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('local runtime callbacks'),
          ),
        ),
      );

      await expectLater(
        transport.sendMessages(
          ChatTransportRequest(
            chatId: 'chat-1',
            prompt: [
              UserPromptMessage.text('Hello'),
            ],
            options: const ChatRequestOptions(
              maxSteps: 3,
            ),
          ),
        ),
        emitsError(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('maxSteps'),
          ),
        ),
      );
    });
  });
}

List<int> _sseFrame(Map<String, Object?> payload) {
  return utf8.encode('data: ${jsonEncode(payload)}\n\n');
}

List<TextStreamEvent> _eventsFromChunks(List<ChatUiStreamChunk> chunks) {
  return chunks
      .whereType<ChatUiEventChunk>()
      .map((chunk) => chunk.event)
      .toList(growable: false);
}

TextStreamEvent _singleEvent(List<ChatUiStreamChunk> chunks) {
  final events = _eventsFromChunks(chunks);
  expect(events, hasLength(1));
  return events.single;
}

final class _TestProviderOptions implements ProviderInvocationOptions {
  final String reasoningEffort;

  const _TestProviderOptions(this.reasoningEffort);
}

typedef _FakeTransportClient = FakeTransportClient;
