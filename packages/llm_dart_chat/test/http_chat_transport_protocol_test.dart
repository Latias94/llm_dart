import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_chat/src/http_chat_transport_protocol_impl.dart'
    as legacy_protocol;
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportProtocolPolicy', () {
    test('freezes supported stream protocol posture', () {
      expect(
        HttpChatTransportProtocolPolicy.defaultStreamProtocol,
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
      );
      expect(
        HttpChatTransportProtocolPolicy.legacyRequestFallbackStreamProtocol,
        HttpChatTransportStreamProtocol.eventStreamV1,
      );
      expect(
        HttpChatTransportProtocolPolicy.supportedStreamProtocols,
        const [
          HttpChatTransportStreamProtocol.eventStreamV1,
          HttpChatTransportStreamProtocol.uiMessageStreamV2,
        ],
      );
    });

    test('new send and reconnect payloads default to v2', () {
      final send = HttpChatTransportRequestPayload(
        chatId: 'chat-1',
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
      );
      final reconnect = HttpChatTransportReconnectRequestPayload(
        chatId: 'chat-1',
        resumeToken: 'resume-1',
      );

      expect(
        send.streamProtocol,
        HttpChatTransportProtocolPolicy.defaultStreamProtocol,
      );
      expect(
        reconnect.streamProtocol,
        HttpChatTransportProtocolPolicy.defaultStreamProtocol,
      );
    });
  });

  group('HttpChatTransportRequestJsonCodec', () {
    test(
        'round-trips prompt, generate options, call options, metadata, and stream protocol',
        () {
      const codec = HttpChatTransportRequestJsonCodec();
      final encoded = codec.encodeRequest(
        HttpChatTransportRequestPayload(
          chatId: 'chat-1',
          prompt: [
            UserPromptMessage.text('Hello'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              description: 'Get weather.',
              inputSchema: ToolJsonSchema.object(
                properties: const {
                  'city': {'type': 'string'},
                },
                required: const ['city'],
              ),
              strict: true,
            ),
          ],
          toolChoice: const SpecificToolChoice('weather'),
          generateOptions: const GenerateTextOptions(
            maxOutputTokens: 256,
            temperature: 0.2,
            stopSequences: ['DONE'],
            topP: 0.9,
            topK: 40,
            presencePenalty: 0.1,
            frequencyPenalty: 0.2,
            seed: 1234,
            reasoning: GenerateTextReasoningOptions(
              enabled: true,
              effort: ReasoningEffort.high,
              budgetTokens: 2048,
            ),
            includeRawChunks: true,
          ),
          callOptions: HttpChatTransportCallOptionsPayload(
            timeout: const Duration(seconds: 5),
            headers: const {
              'x-provider-trace': 'trace-1',
            },
            maxRetries: 2,
            providerOptions: const {
              'reasoningEffort': 'high',
            },
          ),
          streamProtocol: HttpChatTransportStreamProtocol.uiMessageStreamV2,
          metadata: const {
            'clientRequestId': 'req-1',
          },
        ),
      );

      expect(encoded['kind'], HttpChatTransportRequestJsonCodec.envelopeKind);

      final decoded = codec.decodeRequest(encoded);
      expect(decoded.chatId, 'chat-1');
      expect(decoded.prompt.single, isA<UserPromptMessage>());
      expect(decoded.tools, hasLength(1));
      expect(decoded.tools.single.name, 'weather');
      expect(decoded.tools.single.description, 'Get weather.');
      expect(decoded.tools.single.inputSchema.toJson(), {
        'type': 'object',
        'properties': {
          'city': {'type': 'string'},
        },
        'required': ['city'],
      });
      expect(decoded.tools.single.strict, isTrue);
      expect(
        decoded.toolChoice,
        isA<SpecificToolChoice>().having(
          (choice) => choice.toolName,
          'toolName',
          'weather',
        ),
      );
      expect(decoded.generateOptions.maxOutputTokens, 256);
      expect(decoded.generateOptions.temperature, 0.2);
      expect(decoded.generateOptions.stopSequences, ['DONE']);
      expect(decoded.generateOptions.topP, 0.9);
      expect(decoded.generateOptions.topK, 40);
      expect(decoded.generateOptions.presencePenalty, 0.1);
      expect(decoded.generateOptions.frequencyPenalty, 0.2);
      expect(decoded.generateOptions.seed, 1234);
      expect(decoded.generateOptions.reasoning?.enabled, isTrue);
      expect(decoded.generateOptions.reasoning?.effort, ReasoningEffort.high);
      expect(decoded.generateOptions.reasoning?.budgetTokens, 2048);
      expect(decoded.generateOptions.includeRawChunks, isTrue);
      expect(decoded.callOptions.timeout, const Duration(seconds: 5));
      expect(decoded.callOptions.headers, {
        'x-provider-trace': 'trace-1',
      });
      expect(decoded.callOptions.maxRetries, 2);
      expect(decoded.callOptions.providerOptions, {
        'reasoningEffort': 'high',
      });
      expect(
        decoded.streamProtocol,
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
      );
      expect(decoded.metadata, {
        'clientRequestId': 'req-1',
      });
    });

    test('round-trips typed provider tool options through registered codecs',
        () {
      const codec = HttpChatTransportRequestJsonCodec(
        providerToolOptionsCodecs: [
          _TestToolOptionsJsonCodec(),
        ],
      );
      final options = _TestToolOptions('fast');

      final decoded = codec.decodeRequest(
        codec.encodeRequest(
          HttpChatTransportRequestPayload(
            chatId: 'chat-1',
            prompt: [
              UserPromptMessage.text('Hello'),
            ],
            tools: [
              FunctionToolDefinition(
                name: 'weather',
                inputSchema: ToolJsonSchema.object(),
                providerOptions: options,
              ),
            ],
          ),
        ),
      );

      expect(
        decoded.tools.single.providerOptions,
        isA<_TestToolOptions>().having(
          (options) => options.mode,
          'mode',
          'fast',
        ),
      );
    });

    test('rejects unregistered typed provider tool options', () {
      const codec = HttpChatTransportRequestJsonCodec();

      expect(
        () => codec.encodeRequest(
          HttpChatTransportRequestPayload(
            chatId: 'chat-1',
            prompt: [
              UserPromptMessage.text('Hello'),
            ],
            tools: [
              FunctionToolDefinition(
                name: 'weather',
                inputSchema: ToolJsonSchema.object(),
                providerOptions: _TestToolOptions('fast'),
              ),
            ],
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('decodes legacy request payloads without stream protocol as v1', () {
      const codec = HttpChatTransportRequestJsonCodec();

      final decoded = codec.decodeRequest({
        'schemaVersion': llmDartJsonSchemaVersion,
        'kind': HttpChatTransportRequestJsonCodec.envelopeKind,
        'data': {
          'chatId': 'chat-1',
          'prompt': const PromptJsonCodec().encodeMessages([
            UserPromptMessage.text('Hello'),
          ]),
          'generateOptions': <String, Object?>{},
        },
      });

      expect(
        decoded.streamProtocol,
        HttpChatTransportProtocolPolicy.legacyRequestFallbackStreamProtocol,
      );
    });

    test('decodes legacy reconnect payloads without stream protocol as v1', () {
      const codec = HttpChatTransportRequestJsonCodec();

      final decoded = codec.decodeReconnectRequest({
        'schemaVersion': llmDartJsonSchemaVersion,
        'kind': HttpChatTransportRequestJsonCodec.reconnectEnvelopeKind,
        'data': {
          'chatId': 'chat-1',
          'resumeToken': 'resume-1',
        },
      });

      expect(
        decoded.streamProtocol,
        HttpChatTransportProtocolPolicy.legacyRequestFallbackStreamProtocol,
      );
    });

    test('rejects unsupported request schema versions', () {
      const codec = HttpChatTransportRequestJsonCodec();

      expect(
        () => codec.decodeRequest({
          'schemaVersion': '2099-01-1',
          'kind': HttpChatTransportRequestJsonCodec.envelopeKind,
          'data': {
            'chatId': 'chat-1',
            'prompt': const PromptJsonCodec().encodeMessages([
              UserPromptMessage.text('Hello'),
            ]),
            'generateOptions': <String, Object?>{},
          },
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'Unsupported HTTP chat transport schema version "2099-01-1"',
            ),
          ),
        ),
      );
    });

    test('round-trips reconnect request payloads', () {
      const codec = HttpChatTransportRequestJsonCodec();
      final encoded = codec.encodeReconnectRequest(
        HttpChatTransportReconnectRequestPayload(
          chatId: 'chat-1',
          resumeToken: 'resume-2',
          callOptions: HttpChatTransportCallOptionsPayload(
            timeout: const Duration(seconds: 7),
            maxRetries: 1,
          ),
          streamProtocol: HttpChatTransportStreamProtocol.uiMessageStreamV2,
          metadata: const {
            'attempt': 2,
          },
        ),
      );

      expect(
        encoded['kind'],
        HttpChatTransportRequestJsonCodec.reconnectEnvelopeKind,
      );

      final decoded = codec.decodeReconnectRequest(encoded);
      expect(decoded.chatId, 'chat-1');
      expect(decoded.resumeToken, 'resume-2');
      expect(decoded.callOptions.timeout, const Duration(seconds: 7));
      expect(decoded.callOptions.maxRetries, 1);
      expect(
        decoded.streamProtocol,
        HttpChatTransportStreamProtocol.uiMessageStreamV2,
      );
      expect(decoded.metadata, {
        'attempt': 2,
      });
    });
  });

  group('HttpChatTransportChunkJsonCodec', () {
    test('round-trips transport chunks and text stream events', () {
      const codec = HttpChatTransportChunkJsonCodec();
      final chunks = [
        const HttpChatTransportTransportStartChunk(
          requestId: 'req-v2',
          resumeToken: 'resume-v2',
        ),
        const HttpChatTransportStartChunk(
          requestId: 'req-1',
          messageId: 'assistant-1',
          resumeToken: 'resume-1',
        ),
        HttpChatTransportMessageStartChunk(
          messageId: 'assistant-2',
          metadata: const {
            'serverOwned': true,
          },
        ),
        HttpChatTransportMessageMetadataChunk(
          metadata: const {
            'phase': 'streaming',
          },
        ),
        const HttpChatTransportEventChunk(
          TextDeltaEvent(
            id: 'text-1',
            delta: 'Hello',
            providerMetadata: ProviderMetadata({
              'openai': {
                'itemId': 'msg_1',
              },
            }),
          ),
        ),
        const HttpChatTransportDataPartChunk(
          DataUiPart<Object?>(
            id: 'progress',
            key: 'status',
            data: {
              'value': 0.5,
            },
          ),
        ),
        const HttpChatTransportTransientDataPartChunk(
          DataUiPart<Object?>(
            id: 'heartbeat',
            key: 'tool-status',
            data: {
              'phase': 'running',
            },
          ),
        ),
        const HttpChatTransportCheckpointChunk(
          resumeToken: 'resume-2',
          cursor: 'cursor-2',
        ),
        HttpChatTransportMessageFinishChunk(
          metadata: const {
            'persisted': true,
          },
        ),
        const HttpChatTransportFinishChunk(),
        const HttpChatTransportAbortChunk(
          reason: 'cancelled',
        ),
        const HttpChatTransportErrorChunk(
          message: 'backend failed',
          code: 'transport_error',
          details: {
            'retryable': false,
          },
        ),
        const HttpChatTransportKeepAliveChunk(),
      ];

      final decoded = chunks
          .map(codec.encodeChunk)
          .map<Object?>((chunk) => chunk)
          .map(codec.decodeChunk)
          .toList(growable: false);

      expect(decoded[0], isA<HttpChatTransportTransportStartChunk>());
      expect(
        (decoded[0] as HttpChatTransportTransportStartChunk).resumeToken,
        'resume-v2',
      );

      expect(decoded[1], isA<HttpChatTransportStartChunk>());
      expect(
        (decoded[1] as HttpChatTransportStartChunk).resumeToken,
        'resume-1',
      );

      final messageStart = decoded[2] as HttpChatTransportMessageStartChunk;
      expect(messageStart.messageId, 'assistant-2');
      expect(messageStart.metadata['serverOwned'], isTrue);

      final metadataChunk = decoded[3] as HttpChatTransportMessageMetadataChunk;
      expect(metadataChunk.metadata['phase'], 'streaming');

      final eventChunk = decoded[4] as HttpChatTransportEventChunk;
      expect(eventChunk.event, isA<TextDeltaEvent>());
      expect((eventChunk.event as TextDeltaEvent).delta, 'Hello');

      final dataPartChunk = decoded[5] as HttpChatTransportDataPartChunk;
      expect(dataPartChunk.part.id, 'progress');
      expect(dataPartChunk.part.key, 'status');
      expect(
        (dataPartChunk.part.data as Map<String, Object?>)['value'],
        0.5,
      );

      final transientDataPartChunk =
          decoded[6] as HttpChatTransportTransientDataPartChunk;
      expect(transientDataPartChunk.part.id, 'heartbeat');
      expect(transientDataPartChunk.part.key, 'tool-status');
      expect(
        (transientDataPartChunk.part.data as Map<String, Object?>)['phase'],
        'running',
      );

      final checkpoint = decoded[7] as HttpChatTransportCheckpointChunk;
      expect(checkpoint.cursor, 'cursor-2');

      final messageFinish = decoded[8] as HttpChatTransportMessageFinishChunk;
      expect(messageFinish.metadata['persisted'], isTrue);

      expect(decoded[9], isA<HttpChatTransportFinishChunk>());
      expect((decoded[10] as HttpChatTransportAbortChunk).reason, 'cancelled');

      final error = decoded[11] as HttpChatTransportErrorChunk;
      expect(error.code, 'transport_error');
      expect(error.details, {
        'retryable': false,
      });

      expect(decoded[12], isA<HttpChatTransportKeepAliveChunk>());
    });

    test('rejects unsupported chunk schema versions', () {
      const codec = HttpChatTransportChunkJsonCodec();

      expect(
        () => codec.decodeChunk({
          'schemaVersion': '2099-01-1',
          'kind': HttpChatTransportChunkJsonCodec.envelopeKind,
          'data': const {
            'type': 'keepalive',
          },
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'Unsupported HTTP chat transport schema version "2099-01-1"',
            ),
          ),
        ),
      );
    });
  });

  test('legacy protocol implementation barrel forwards split protocol names',
      () {
    const codec = legacy_protocol.HttpChatTransportChunkJsonCodec();
    final envelope = codec.encodeChunk(
      const legacy_protocol.HttpChatTransportKeepAliveChunk(),
    );

    expect(
      codec.decodeChunk(envelope),
      isA<legacy_protocol.HttpChatTransportKeepAliveChunk>(),
    );
  });
}

final class _TestToolOptions implements ProviderToolOptions {
  final String mode;

  const _TestToolOptions(this.mode);
}

final class _TestToolOptionsJsonCodec
    implements ProviderToolOptionsJsonCodec<_TestToolOptions> {
  const _TestToolOptionsJsonCodec();

  @override
  String get type => 'test.toolOptions';

  @override
  bool canEncode(ProviderToolOptions options) => options is _TestToolOptions;

  @override
  Map<String, Object?> encode(ProviderToolOptions options) {
    final typed = options as _TestToolOptions;
    return {'mode': typed.mode};
  }

  @override
  _TestToolOptions decode(Map<String, Object?> json) {
    return _TestToolOptions(json['mode']! as String);
  }
}
