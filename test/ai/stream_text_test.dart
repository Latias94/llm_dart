library;

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

class _FakeChatResponseWithFinishReason extends _FakeChatResponse
    implements ChatResponseWithFinishReason {
  @override
  final LLMFinishReason? finishReason;

  const _FakeChatResponseWithFinishReason({
    super.text,
    super.thinking,
    super.toolCalls,
    super.usage,
    super.providerMetadata,
    this.finishReason,
  });
}

class _FakeChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<LLMStreamPart> parts;

  _FakeChatModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final part in parts) {
      yield part;
    }
  }
}

class _SequencedStreamChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<List<LLMStreamPart>> steps;

  _SequencedStreamChatModel(this.steps);

  var _index = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (_index >= steps.length) {
      throw StateError('No more stream steps configured for fake model');
    }
    final parts = steps[_index++];
    for (final part in parts) {
      yield part;
    }
  }
}

void main() {
  group('streamText', () {
    test('aggregates text and exposes finalResult', () async {
      final usage =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      const finishReason = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );
      const warnings = [
        {'type': 'warning', 'message': 'test warning'}
      ];

      final model = _FakeChatModel([
        const LLMStreamStartPart(warnings: warnings),
        const LLMRequestMetadataPart(body: {
          'messages': ['hi']
        }),
        LLMResponseMetadataPart(
          id: 'resp_1',
          timestamp: DateTime.utc(2020, 1, 1),
          model: 'm1',
        ),
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Hel'),
        const LLMTextDeltaPart('lo'),
        const LLMTextEndPart('Hello'),
        LLMProviderMetadataPart(const {
          'openai': {'id': 'resp_1'}
        }),
        LLMFinishPart(
          _FakeChatResponse(
            text: 'Hello',
            usage: usage,
            providerMetadata: const {
              'openai': {'id': 'resp_1'}
            },
          ),
          usage: usage,
          finishReason: finishReason,
        ),
      ]);

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      final partsFuture = result.fullStream.toList();

      expect(await result.warnings, equals(warnings));
      expect((await result.responseMetadata)?.id, equals('resp_1'));
      expect(
          (await result.requestMetadata)?.body,
          equals({
            'messages': ['hi']
          }));
      expect(await result.text, equals('Hello'));
      expect((await result.usage)?.totalTokens, equals(3));
      expect((await result.totalUsage)?.totalTokens, equals(3));
      expect((await result.finishReason)?.unified,
          equals(LLMUnifiedFinishReason.stop));
      expect(await result.providerMetadata, contains('openai'));
      expect(await result.steps, hasLength(1));

      final finalResult = await result.finalResult;
      expect(finalResult.text, equals('Hello'));
      expect(finalResult.finishReason?.unified,
          equals(LLMUnifiedFinishReason.stop));
      expect(finalResult.usage?.totalTokens, equals(3));
      expect(finalResult.providerMetadata, contains('openai'));

      final parts = await partsFuture;
      expect(parts.first, isA<LLMStreamStartPart>());
      expect(parts.last, isA<LLMFinishPart>());
    });

    test('filters raw chunks unless includeRawChunks is enabled', () async {
      final parts = <LLMStreamPart>[
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Hi'),
        const LLMRawPart({'raw': true}),
        const LLMTextEndPart('Hi'),
        LLMFinishPart(const _FakeChatResponse(text: 'Hi')),
      ];

      final modelNoRaw = _FakeChatModel(parts);
      final resultNoRaw = streamText(
        model: modelNoRaw,
        messages: [ChatMessage.user('hi')],
      );
      final collectedNoRaw = await resultNoRaw.fullStream.toList();
      expect(collectedNoRaw.whereType<LLMRawPart>(), isEmpty);

      final modelWithRaw = _FakeChatModel(parts);
      final resultWithRaw = streamText(
        model: modelWithRaw,
        messages: [ChatMessage.user('hi')],
        includeRawChunks: true,
      );
      final collectedWithRaw = await resultWithRaw.fullStream.toList();
      expect(collectedWithRaw.whereType<LLMRawPart>(), hasLength(1));
    });

    test('toolSet path exposes steps and totalUsage', () async {
      final usage1 =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      final usage2 =
          UsageInfo(promptTokens: 10, completionTokens: 20, totalTokens: 30);

      const finishReasonToolCalls = LLMFinishReason(
        unified: LLMUnifiedFinishReason.toolCalls,
        raw: 'tool_calls',
      );

      const finishReasonStop = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );

      final model = _SequencedStreamChatModel([
        [
          const LLMResponseMetadataPart(
            id: 'resp_step_1',
            headers: {'x-step': '1'},
          ),
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Need '),
          LLMToolCallStartPart(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: 'get_weather', arguments: '{'),
            ),
          ),
          LLMToolCallDeltaPart(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: '', arguments: '"city":"SF"}'),
            ),
          ),
          const LLMTextEndPart('Need '),
          const LLMToolCallEndPart('call_1'),
          LLMFinishPart(
            _FakeChatResponseWithFinishReason(
              usage: usage1,
              finishReason: finishReasonToolCalls,
              providerMetadata: const {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMResponseMetadataPart(
            id: 'resp_step_2',
            headers: {'x-step': '2'},
          ),
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          LLMFinishPart(
            _FakeChatResponseWithFinishReason(
              text: 'Done',
              usage: usage2,
              finishReason: finishReasonStop,
              providerMetadata: const {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final toolSet = ToolSet([
        functionTool(
          name: 'get_weather',
          description: 'get weather',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {
              'city': ParameterProperty(
                propertyType: 'string',
                description: 'city',
              ),
            },
            required: ['city'],
          ),
          handler: (toolCall, {cancelToken}) => {'temp': 70},
        ),
      ]);

      final finishedSteps = <int>[];
      StreamTextFinishEvent? finishEvent;

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolSet: toolSet,
        maxSteps: 5,
        onStepFinish: (step) => finishedSteps.add(step.index),
        onFinish: (event) => finishEvent = event,
      );

      final parts = await result.fullStream.toList();
      await result.done;
      expect(await result.warnings, isEmpty);
      expect(parts.whereType<LLMStepStartPart>(), hasLength(2));
      expect(parts.whereType<LLMStepFinishPart>(), hasLength(2));
      expect(finishedSteps, equals([0, 1]));

      // AI SDK semantics: `text` is from the last step.
      expect(await result.text, equals('Done'));

      final steps = await result.steps;
      expect(steps, hasLength(2));
      expect(steps[0].toolCalls, hasLength(1));
      expect(steps[0].toolResults, hasLength(1));
      expect(steps[0].responseMetadata?.headers, containsPair('x-step', '1'));
      expect(steps[0].toolResults.single.result, equals({'temp': 70}));
      expect(steps[1].toolCalls, isEmpty);
      expect(steps[1].responseMetadata?.headers, containsPair('x-step', '2'));
      expect(
        (await result.responseMetadata)?.headers,
        containsPair('x-step', '2'),
      );

      final totalUsage = await result.totalUsage;
      expect(totalUsage?.totalTokens, equals(33));

      expect(finishEvent, isNotNull);
      expect(finishEvent!.steps, hasLength(2));
      expect(finishEvent!.totalUsage?.totalTokens, equals(33));
    });

    test('yields error part when model lacks parts-first streaming', () async {
      final model = _NonPartsModel();

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      final parts = await result.fullStream.toList();
      expect(parts.whereType<LLMErrorPart>(), hasLength(1));
      expect(() async => await result.text, throwsA(isA<LLMError>()));
      expect(() async => await result.warnings, throwsA(isA<LLMError>()));
      expect(() async => await result.steps, throwsA(isA<LLMError>()));
    });

    test('content preserves stream order within a step', () async {
      const toolCallId = 'call_1';
      const usage =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      const finishReason = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );

      final mergedToolCall = ToolCall(
        id: toolCallId,
        callType: 'function',
        function: const FunctionCall(
          name: 'myTool',
          arguments: '{"x":1}',
        ),
      );

      final toolResult = ToolResult.success(
        toolCallId: toolCallId,
        result: const {'ok': true},
      );

      final response = const _FakeChatResponseWithFinishReason(
        text: 'done',
        usage: usage,
        finishReason: finishReason,
      );

      final model = _FakeChatModel([
        const LLMStepStartPart(0),
        const LLMTextStartPart(blockId: 't1'),
        const LLMTextDeltaPart('hi', blockId: 't1'),
        const LLMTextEndPart('hi', blockId: 't1'),
        LLMToolCallStartPart(
          ToolCall(
            id: toolCallId,
            callType: 'function',
            function: const FunctionCall(
              name: 'myTool',
              arguments: '{',
            ),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: toolCallId,
            callType: 'function',
            function: const FunctionCall(
              name: '',
              arguments: '"x":1}',
            ),
          ),
        ),
        const LLMToolCallEndPart(toolCallId),
        LLMToolResultPart(toolResult),
        LLMStepFinishPart(
          stepIndex: 0,
          response: response,
          usage: usage,
          finishReason: finishReason,
          toolCalls: [mergedToolCall],
          toolResults: [toolResult],
        ),
        LLMFinishPart(
          response,
          usage: usage,
          finishReason: finishReason,
        ),
      ]);

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      final steps = await result.steps;
      expect(steps, hasLength(1));

      final stepContent = steps.single.result.content;
      expect(stepContent.map((p) => p.type).toList(), [
        'text',
        'tool-call',
        'tool-result',
      ]);

      final toolCallPart = stepContent[1] as ToolCallContentPart;
      expect(toolCallPart.toolCall.id, equals(toolCallId));
      expect(toolCallPart.toolCall.function.name, equals('myTool'));
      expect(toolCallPart.toolCall.function.arguments, equals('{"x":1}'));

      final toolResultPart = stepContent[2] as ToolResultContentPart;
      expect(toolResultPart.toolResult.toolCallId, equals(toolCallId));

      final finalContent = await result.content;
      expect(finalContent.map((p) => p.type).toList(), [
        'text',
        'tool-call',
        'tool-result',
      ]);
    });

    test('content includes provider tool call and result', () async {
      const usage =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      const finishReason = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );

      const response = _FakeChatResponseWithFinishReason(
        text: 'done',
        usage: usage,
        finishReason: finishReason,
      );

      final model = _FakeChatModel([
        const LLMProviderToolCallPart(
          toolCallId: 'pt1',
          toolName: 'web_search',
          input: {'query': 'dart'},
          providerExecuted: true,
        ),
        const LLMProviderToolResultPart(
          toolCallId: 'pt1',
          toolName: 'web_search',
          result: {
            'results': [
              {'title': 'Dart', 'url': 'https://dart.dev'}
            ],
          },
          isError: false,
        ),
        const LLMFinishPart(
          response,
          usage: usage,
          finishReason: finishReason,
        ),
      ]);

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      final content = await result.content;
      expect(content.map((p) => p.type).toList(), [
        'text',
        'tool-call',
        'tool-result',
      ]);
      expect(content[0], isA<TextContentPart>());
      expect((content[0] as TextContentPart).text, equals('done'));
      expect(content[1], isA<ProviderToolCallContentPart>());
      expect(content[2], isA<ProviderToolResultContentPart>());

      final call = content[1] as ProviderToolCallContentPart;
      expect(call.toolCallId, equals('pt1'));
      expect(call.toolName, equals('web_search'));
      expect(call.input, isA<Map<String, Object?>>());

      final toolResult = content[2] as ProviderToolResultContentPart;
      expect(toolResult.toolCallId, equals('pt1'));
      expect(toolResult.toolName, equals('web_search'));
    });

    test('content includes provider tool delta (status update)', () async {
      const usage =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      const finishReason = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );

      const response = _FakeChatResponseWithFinishReason(
        text: 'done',
        usage: usage,
        finishReason: finishReason,
      );

      final model = _FakeChatModel([
        const LLMProviderToolCallPart(
          toolCallId: 'pt1',
          toolName: 'web_search',
          input: {'query': 'dart'},
          providerExecuted: true,
        ),
        const LLMProviderToolDeltaPart(
          toolCallId: 'pt1',
          toolName: 'web_search',
          status: 'in_progress',
          data: {'phase': 'searching'},
        ),
        const LLMProviderToolResultPart(
          toolCallId: 'pt1',
          toolName: 'web_search',
          result: {
            'results': [
              {'title': 'Dart', 'url': 'https://dart.dev'}
            ],
          },
          isError: false,
        ),
        const LLMFinishPart(
          response,
          usage: usage,
          finishReason: finishReason,
        ),
      ]);

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      final content = await result.content;
      expect(content.map((p) => p.type).toList(), [
        'text',
        'tool-call',
        'provider-tool-delta',
        'tool-result',
      ]);
      expect(content[2], isA<ProviderToolDeltaContentPart>());
      final delta = content[2] as ProviderToolDeltaContentPart;
      expect(delta.toolCallId, equals('pt1'));
      expect(delta.toolName, equals('web_search'));
      expect(delta.status, equals('in_progress'));
      expect(delta.data, isA<Map<String, Object?>>());
    });

    test('content includes provider tool approval request when blocked',
        () async {
      final parts = <LLMStreamPart>[
        const LLMProviderToolCallPart(
          toolCallId: 'pt1',
          toolName: 'mcp_server.doThing',
          input: {'x': 1},
          providerExecuted: true,
        ),
        const LLMProviderToolApprovalRequestPart(
          approvalId: 'appr_1',
          toolCallId: 'pt1',
          toolName: 'mcp_server.doThing',
          input: {'x': 1},
        ),
        LLMFinishPart(
          const _FakeChatResponse(text: ''),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.toolCalls,
            raw: null,
          ),
        ),
      ];

      final result = StreamTextResult.fromPartsStream(
        Stream<LLMStreamPart>.fromIterable(parts),
      );

      final content = await result.content;
      expect(content.map((p) => p.type).toList(), [
        'tool-call',
        'tool-approval-request',
      ]);
      expect(content[0], isA<ProviderToolCallContentPart>());
      expect(content[1], isA<ProviderToolApprovalRequestContentPart>());

      final request = content[1] as ProviderToolApprovalRequestContentPart;
      expect(request.approvalId, equals('appr_1'));
      expect(request.toolCallId, equals('pt1'));
      expect(request.toolName, equals('mcp_server.doThing'));
      expect(request.input, equals({'x': 1}));
    });
  });
}

class _NonPartsModel extends ChatCapability {
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return const _FakeChatResponse(text: 'nope');
  }
}
