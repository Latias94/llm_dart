library;

import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  final Map<String, dynamic>? _providerMetadata;

  const _FakeChatResponse({
    this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    Map<String, dynamic>? providerMetadata,
  }) : _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _FakeChatModel extends ChatCapability {
  final ChatResponse response;
  final List<ChatStreamEvent> streamEvents;

  _FakeChatModel({
    required this.response,
    this.streamEvents = const [],
  });

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return response;
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final event in streamEvents) {
      yield event;
    }
  }
}

class _FakeEmbeddingModel extends EmbeddingCapability {
  final List<List<double>> vectors;
  _FakeEmbeddingModel(this.vectors);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return vectors;
  }
}

class _FakeImageModel extends ImageGenerationCapability {
  final ImageGenerationResponse response;
  _FakeImageModel(this.response);

  @override
  Future<ImageGenerationResponse> generateImages(
      ImageGenerationRequest request) async {
    return response;
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    throw UnsupportedError('editImage not implemented in fake');
  }

  @override
  Future<ImageGenerationResponse> createVariation(
      ImageVariationRequest request) async {
    throw UnsupportedError('createVariation not implemented in fake');
  }

  @override
  List<String> getSupportedSizes() => const ['1024x1024'];

  @override
  List<String> getSupportedFormats() => const ['url', 'b64_json'];
}

class _FakeAudioModel
    implements
        TextToSpeechCapability,
        StreamingTextToSpeechCapability,
        SpeechToTextCapability {
  final TTSResponse ttsResponse;
  final STTResponse sttResponse;
  final List<AudioStreamEvent> streamEvents;

  _FakeAudioModel({
    required this.ttsResponse,
    required this.sttResponse,
    this.streamEvents = const [],
  });

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    return ttsResponse;
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async* {
    for (final event in streamEvents) {
      yield event;
    }
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) async {
    return sttResponse;
  }
}

class _SequencedChatModel extends ChatCapability {
  final List<ChatResponse> responses;
  final List<List<ChatMessage>> calls = [];

  _SequencedChatModel(this.responses);

  var _index = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    calls.add(List<ChatMessage>.from(messages));
    if (_index >= responses.length) {
      throw StateError('No more responses configured for fake model');
    }
    return responses[_index++];
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {}
}

class _SequencedStreamChatModel extends ChatCapability {
  final List<List<ChatStreamEvent>> eventSteps;
  final List<List<ChatMessage>> calls = [];

  _SequencedStreamChatModel(this.eventSteps);

  var _index = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('chatWithTools not used in this fake');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    calls.add(List<ChatMessage>.from(messages));
    if (_index >= eventSteps.length) {
      throw StateError('No more stream steps configured for fake model');
    }
    final events = eventSteps[_index++];
    for (final event in events) {
      yield event;
    }
  }
}

void main() {
  group('llm_dart_ai', () {
    test('generateText maps response fields', () async {
      final response = _FakeChatResponse(
        text: 'hello',
        thinking: 'thinking...',
        toolCalls: const [
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(name: 't', arguments: '{"a":1}'),
          ),
        ],
        usage: const UsageInfo(promptTokens: 1, completionTokens: 2),
        providerMetadata: const {
          'fake': {'id': 'resp_1'}
        },
      );
      final model = _FakeChatModel(response: response);

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: const [],
      );

      expect(result.text, 'hello');
      expect(result.thinking, 'thinking...');
      expect(result.toolCalls, isNotNull);
      expect(result.toolCalls!.single.function.name, 't');
      expect(result.usage?.promptTokens, 1);
      expect(result.rawResponse, same(response));
      expect(result.providerMetadata, const {
        'fake': {'id': 'resp_1'}
      });
    });

    test('generateText standardizes (system + prompt) into messages', () async {
      final response = _FakeChatResponse(text: 'ok');
      final model = _SequencedChatModel([response]);

      await generateText(
        model: model,
        system: 'sys',
        prompt: 'hello',
      );

      expect(model.calls, hasLength(1));
      final call = model.calls.single;
      expect(call, hasLength(2));
      expect(call[0].role, ChatRole.system);
      expect(call[0].content, 'sys');
      expect(call[1].role, ChatRole.user);
      expect(call[1].content, 'hello');
    });

    test('generateText rejects ambiguous prompt inputs', () async {
      final response = _FakeChatResponse(text: 'ok');
      final model = _FakeChatModel(response: response);

      await expectLater(
        generateText(
          model: model,
          prompt: 'hi',
          messages: [ChatMessage.user('x')],
        ),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('streamText maps stream events to parts', () async {
      final response = _FakeChatResponse(text: 'done');
      final model = _FakeChatModel(
        response: response,
        streamEvents: [
          const TextDeltaEvent('a'),
          const ThinkingDeltaEvent('b'),
          const ToolCallDeltaEvent(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: 't', arguments: '{}'),
            ),
          ),
          CompletionEvent(response),
        ],
      );

      final parts = await streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts[0], isA<TextDeltaPart>());
      expect((parts[0] as TextDeltaPart).delta, 'a');
      expect(parts[1], isA<ThinkingDeltaPart>());
      expect((parts[1] as ThinkingDeltaPart).delta, 'b');
      expect(parts[2], isA<ToolCallDeltaPart>());
      expect((parts[2] as ToolCallDeltaPart).toolCall.function.name, 't');
      expect(parts[3], isA<FinishPart>());
      expect((parts[3] as FinishPart).result.text, 'done');
    });

    test('embed forwards to EmbeddingCapability', () async {
      final model = _FakeEmbeddingModel(const [
        [0.1, 0.2],
      ]);

      final vectors = await embed(model: model, input: const ['x']);

      expect(vectors, hasLength(1));
      expect(vectors.single, [0.1, 0.2]);
    });

    test('generateObject parses tool call arguments', () async {
      const schema = ParametersSchema(
        schemaType: 'object',
        properties: {
          'answer': ParameterProperty(
            propertyType: 'string',
            description: 'Answer text',
          ),
        },
        required: ['answer'],
      );

      final response = _FakeChatResponse(
        toolCalls: const [
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
                name: 'return_object', arguments: '{"answer":"ok"}'),
          ),
        ],
      );
      final model = _FakeChatModel(response: response);

      final result = await generateObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      expect(result.object['answer'], 'ok');
      expect(result.rawResponse, same(response));
    });

    test('generateImage forwards to ImageGenerationCapability', () async {
      final response = ImageGenerationResponse(
        images: const [
          GeneratedImage(url: 'https://example.com/a.png'),
        ],
        model: 'm',
      );
      final model = _FakeImageModel(response);

      final result = await generateImage(
        model: model,
        request: const ImageGenerationRequest(
          prompt: 'cat',
          model: 'm',
          count: 1,
        ),
      );

      expect(result.rawResponse, same(response));
      expect(result.images.single.url, 'https://example.com/a.png');
      expect(result.model, 'm');
    });

    test('generateSpeech forwards to TextToSpeechCapability.textToSpeech',
        () async {
      final model = _FakeAudioModel(
        ttsResponse: const TTSResponse(
          audioData: [1, 2, 3],
          contentType: 'audio/mpeg',
        ),
        sttResponse: const STTResponse(text: 'ignored'),
      );

      final result = await generateSpeechFromText(
        model: model,
        text: 'hi',
        voice: 'v',
      );

      expect(result.audioData, [1, 2, 3]);
      expect(result.contentType, 'audio/mpeg');
      expect(result.rawResponse.audioData, [1, 2, 3]);
    });

    test('streamSpeech forwards AudioStreamEvent stream', () async {
      final model = _FakeAudioModel(
        ttsResponse: const TTSResponse(audioData: []),
        sttResponse: const STTResponse(text: 'ignored'),
        streamEvents: const [
          AudioMetadataEvent(contentType: 'audio/mpeg'),
          AudioDataEvent(data: [1, 2]),
          AudioDataEvent(data: [3], isFinal: true),
        ],
      );

      final events =
          await streamSpeechFromText(model: model, text: 'hi').toList();

      expect(events, hasLength(3));
      expect(events[0], isA<AudioMetadataEvent>());
      expect((events[1] as AudioDataEvent).data, [1, 2]);
      expect((events[2] as AudioDataEvent).isFinal, isTrue);
    });

    test('transcribe forwards to SpeechToTextCapability.speechToText',
        () async {
      final model = _FakeAudioModel(
        ttsResponse: const TTSResponse(audioData: []),
        sttResponse: const STTResponse(text: 'hello'),
      );

      final result = await transcribeFromAudioBytes(
        model: model,
        audioData: const [0, 1],
      );

      expect(result.text, 'hello');
      expect(result.rawResponse.text, 'hello');
    });

    test('runToolLoop executes tools and returns final response', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
      );

      final model = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
        const _FakeChatResponse(text: 'done'),
      ]);

      final result = await runToolLoop(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'sum',
            description: 'sum a and b',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {
                'a': ParameterProperty(
                  propertyType: 'number',
                  description: 'a',
                ),
                'b': ParameterProperty(
                  propertyType: 'number',
                  description: 'b',
                ),
              },
              required: ['a', 'b'],
            ),
          ),
        ],
        toolHandlers: {
          'sum': (call, {cancelToken}) async {
            final args = jsonDecode(call.function.arguments) as Map;
            final a = (args['a'] as num).toInt();
            final b = (args['b'] as num).toInt();
            return {'result': a + b};
          },
        },
        maxSteps: 5,
      );

      expect(result.finalResult.text, 'done');
      expect(result.steps, hasLength(2));
      expect(model.calls, hasLength(2));

      final secondCallMessages = model.calls[1];
      expect(secondCallMessages, hasLength(3));
      expect(secondCallMessages[1].messageType, isA<ToolUseMessage>());
      expect(secondCallMessages[2].messageType, isA<ToolResultMessage>());

      final toolResultMessage = secondCallMessages[2];
      final results =
          (toolResultMessage.messageType as ToolResultMessage).results;
      expect(results, hasLength(1));
      expect(results.single.id, 'call_1');
      final parsed = jsonDecode(results.single.function.arguments);
      expect(parsed, equals({'result': 3}));
      expect(toolResultMessage.content, isEmpty);
    });

    test(
        'runToolLoopUntilBlocked returns blocked state when approval is required',
        () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
      );

      final model = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
      ]);

      final outcome = await runToolLoopUntilBlocked(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'sum': (call, {cancelToken}) => {'result': 3},
        },
        needsApproval: (call,
                {required messages, required stepIndex, cancelToken}) =>
            true,
        maxSteps: 5,
      );

      expect(outcome, isA<ToolLoopBlocked>());
      final blocked = outcome as ToolLoopBlocked;
      expect(blocked.state.toolCallsNeedingApproval, hasLength(1));
      expect(blocked.state.toolCallsNeedingApproval.single.id, 'call_1');
      expect(blocked.state.messages.last.messageType, isA<ToolUseMessage>());
      expect(
        blocked.state.messages.where((m) => m.messageType is ToolResultMessage),
        isEmpty,
      );
    });

    test(
        'runToolLoop throws ToolApprovalRequiredError when approval is required',
        () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
      );

      final model = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
      ]);

      expect(
        () => runToolLoop(
          model: model,
          messages: [ChatMessage.user('hi')],
          toolHandlers: {
            'sum': (call, {cancelToken}) => {'result': 3},
          },
          needsApproval: (call,
                  {required messages, required stepIndex, cancelToken}) =>
              true,
          maxSteps: 5,
        ),
        throwsA(
          predicate(
            (e) =>
                e is ToolApprovalRequiredError &&
                e.state.toolCallsNeedingApproval.single.id == 'call_1',
          ),
        ),
      );
    });

    test('blocked tool loop can be resumed manually', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
      );

      final firstModel = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
      ]);

      final outcome = await runToolLoopUntilBlocked(
        model: firstModel,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'sum': (call, {cancelToken}) => {'result': 3},
        },
        needsApproval: (call,
                {required messages, required stepIndex, cancelToken}) =>
            true,
        maxSteps: 5,
      );

      final blocked = outcome as ToolLoopBlocked;

      final toolResults = await executeToolCalls(
        toolCalls: blocked.state.toolCalls,
        toolHandlers: {
          'sum': (call, {cancelToken}) => {'result': 3},
        },
      );

      final resumedMessages = [
        ...blocked.state.messages,
        ChatMessage.toolResult(
          results: encodeToolResultsAsToolCalls(
            toolCalls: blocked.state.toolCalls,
            toolResults: toolResults,
          ),
        ),
      ];

      final secondModel = _SequencedChatModel([
        const _FakeChatResponse(text: 'done'),
      ]);

      final result = await runToolLoop(
        model: secondModel,
        messages: resumedMessages,
        toolHandlers: const {},
        maxSteps: 5,
      );

      expect(result.finalResult.text, 'done');
      expect(secondModel.calls.single, hasLength(3));
      expect(secondModel.calls.single[1].messageType, isA<ToolUseMessage>());
      expect(secondModel.calls.single[2].messageType, isA<ToolResultMessage>());
    });

    test('runToolLoop encodes tool errors as JSON object', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'boom', arguments: '{}'),
      );

      final model = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
        const _FakeChatResponse(text: 'done'),
      ]);

      final result = await runToolLoop(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'boom': (call, {cancelToken}) {
            throw StateError('nope');
          },
        },
        maxSteps: 5,
      );

      expect(result.finalResult.text, 'done');
      final toolResultMessage = model.calls[1][2];
      final results =
          (toolResultMessage.messageType as ToolResultMessage).results;
      final parsed = jsonDecode(results.single.function.arguments) as Map;
      expect(parsed['error'], isNotNull);
    });

    test('runToolLoop throws when exceeding maxSteps', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'noop', arguments: '{}'),
      );

      final model = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
      ]);

      expect(
        () => runToolLoop(
          model: model,
          messages: [ChatMessage.user('hi')],
          toolHandlers: {
            'noop': (call, {cancelToken}) => {'ok': true},
          },
          maxSteps: 1,
        ),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('streamToolLoop runs tools and continues streaming', () async {
      final toolCall1 = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,'),
      );
      final toolCall2 = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: '', arguments: '"b":2}'),
      );

      final model = _SequencedStreamChatModel([
        [
          ToolCallDeltaEvent(toolCall1),
          ToolCallDeltaEvent(toolCall2),
          const CompletionEvent(_FakeChatResponse()),
        ],
        [
          const TextDeltaEvent('done'),
          const CompletionEvent(_FakeChatResponse(text: '')),
        ],
      ]);

      final parts = await streamToolLoop(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'sum': (call, {cancelToken}) async {
            final args = jsonDecode(call.function.arguments) as Map;
            final a = (args['a'] as num).toInt();
            final b = (args['b'] as num).toInt();
            return {'result': a + b};
          },
        },
        maxSteps: 5,
      ).toList();

      expect(parts.whereType<ToolCallDeltaPart>(), hasLength(2));
      expect(
        parts.whereType<TextDeltaPart>().map((p) => p.delta).toList().join(),
        'done',
      );

      final finish = parts.last as FinishPart;
      expect(finish.result.text, 'done');

      // Second step should include tool use + tool result messages.
      expect(model.calls, hasLength(2));
      final secondCallMessages = model.calls[1];
      expect(secondCallMessages, hasLength(3));
      expect(secondCallMessages[1].messageType, isA<ToolUseMessage>());
      expect(secondCallMessages[2].messageType, isA<ToolResultMessage>());

      final toolResultMessage = secondCallMessages[2];
      final results =
          (toolResultMessage.messageType as ToolResultMessage).results;
      final parsed = jsonDecode(results.single.function.arguments);
      expect(parsed, equals({'result': 3}));
    });

    test(
        'streamToolLoop yields ToolApprovalRequiredError when approval is required',
        () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
      );

      final model = _SequencedStreamChatModel([
        [
          ToolCallDeltaEvent(toolCall),
          const CompletionEvent(_FakeChatResponse()),
        ],
      ]);

      final parts = await streamToolLoop(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: const {},
        needsApproval: (call,
                {required messages, required stepIndex, cancelToken}) =>
            true,
        maxSteps: 5,
      ).toList();

      expect(parts.whereType<ToolCallDeltaPart>(), hasLength(1));
      expect(parts.last, isA<ErrorPart>());
      final err = (parts.last as ErrorPart).error;
      expect(err, isA<ToolApprovalRequiredError>());
      final approval = err as ToolApprovalRequiredError;
      expect(approval.state.toolCallsNeedingApproval.single.id, 'call_1');
    });

    test('streamToolLoop yields ErrorPart when exceeding maxSteps', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'noop', arguments: '{}'),
      );

      final model = _SequencedStreamChatModel([
        [
          ToolCallDeltaEvent(toolCall),
          const CompletionEvent(_FakeChatResponse()),
        ],
      ]);

      final parts = await streamToolLoop(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'noop': (call, {cancelToken}) => {'ok': true},
        },
        maxSteps: 1,
      ).toList();

      final last = parts.last;
      expect(last, isA<ErrorPart>());
      expect((last as ErrorPart).error, isA<InvalidRequestError>());
    });

    test('ToolSet works with runToolLoopWithToolSet', () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
      );

      final model = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
        const _FakeChatResponse(text: 'done'),
      ]);

      final toolSet = ToolSet([
        functionTool(
          name: 'sum',
          description: 'sum a and b',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {
              'a': ParameterProperty(propertyType: 'number', description: 'a'),
              'b': ParameterProperty(propertyType: 'number', description: 'b'),
            },
            required: ['a', 'b'],
          ),
          handler: (call, {cancelToken}) async {
            final args = jsonDecode(call.function.arguments) as Map;
            final a = (args['a'] as num).toInt();
            final b = (args['b'] as num).toInt();
            return {'result': a + b};
          },
        ),
      ]);

      final result = await runToolLoopWithToolSet(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolSet: toolSet,
      );

      expect(result.finalResult.text, 'done');
    });

    test(
        'ToolSet supports needsApproval via runToolLoopUntilBlockedWithToolSet',
        () async {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(name: 'sum', arguments: '{"a":1,"b":2}'),
      );

      final model = _SequencedChatModel([
        _FakeChatResponse(toolCalls: [toolCall]),
      ]);

      final toolSet = ToolSet([
        functionTool(
          name: 'sum',
          description: 'sum',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {
              'a': ParameterProperty(propertyType: 'number', description: 'a'),
              'b': ParameterProperty(propertyType: 'number', description: 'b'),
            },
            required: ['a', 'b'],
          ),
          handler: (call, {cancelToken}) => {'result': 3},
          needsApproval: (call,
                  {required messages, required stepIndex, cancelToken}) =>
              true,
        ),
      ]);

      final outcome = await runToolLoopUntilBlockedWithToolSet(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolSet: toolSet,
      );

      expect(outcome, isA<ToolLoopBlocked>());
    });
  });
}
