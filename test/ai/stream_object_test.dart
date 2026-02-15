library;

import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponseWithFinishReason
    implements ChatResponseWithFinishReason {
  @override
  final LLMFinishReason? finishReason;

  @override
  final UsageInfo? usage;

  final Map<String, dynamic>? _providerMetadata;

  const _FakeChatResponseWithFinishReason({
    this.finishReason,
    this.usage,
    Map<String, dynamic>? providerMetadata,
  }) : _providerMetadata = providerMetadata;

  @override
  String? get text => null;

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _FakeStreamChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<LLMStreamPart> parts;

  _FakeStreamChatModel(this.parts);

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
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final part in parts) {
      yield part;
    }
  }
}

class _ProviderApprovalObjectModel extends ChatCapability
    implements PromptChatStreamPartsCapability {
  var calls = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('not used');
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    calls++;

    if (calls == 1) {
      yield const LLMStreamStartPart();
      yield const LLMProviderToolCallPart(
        toolCallId: 'call_mcp_1',
        toolName: 'mcp.web_search',
        input: {'q': 'hello'},
        providerExecuted: true,
      );
      yield const LLMProviderToolApprovalRequestPart(
        approvalId: 'apr_1',
        toolCallId: 'call_mcp_1',
        toolName: 'mcp.web_search',
        input: {'q': 'hello'},
      );
      return;
    }

    if (calls == 2) {
      final last = prompt.messages.last;
      if (last.role != PromptRole.tool) {
        throw StateError('Expected last prompt message to be tool role.');
      }

      final approvals =
          last.parts.whereType<ToolApprovalResponsePart>().toList();
      if (approvals.length != 1) {
        throw StateError('Expected exactly one ToolApprovalResponsePart.');
      }
      final approval = approvals.single;
      if (approval.approvalId != 'apr_1' || approval.approved != true) {
        throw StateError('Unexpected approval response.');
      }

      yield const LLMStreamStartPart();
      yield LLMToolCallStartPart(
        ToolCall(
          id: 'call_1',
          callType: 'function',
          function: FunctionCall(
            name: 'return_object',
            arguments: '{"city":"SF","temp":70}',
          ),
        ),
      );
      yield const LLMToolCallEndPart('call_1');
      yield const LLMFinishPart(
        _FakeChatResponseWithFinishReason(
          finishReason: LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: 'stop',
          ),
        ),
      );
      return;
    }

    throw StateError('Unexpected number of calls: $calls');
  }
}

void main() {
  group('streamObject', () {
    const schema = ParametersSchema(
      schemaType: 'object',
      properties: {
        'city': ParameterProperty(
          propertyType: 'string',
          description: 'city',
        ),
        'temp': ParameterProperty(
          propertyType: 'number',
          description: 'temp',
        ),
      },
      required: ['city'],
    );

    test('parses final object from tool call arguments', () async {
      const usage =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      const finishReason = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );
      const warnings = [
        {'type': 'warning', 'message': 'test warning'}
      ];

      final model = _FakeStreamChatModel([
        const LLMStreamStartPart(warnings: warnings),
        const LLMRequestMetadataPart(body: {
          'messages': ['hi']
        }),
        LLMResponseMetadataPart(
          id: 'resp_1',
          timestamp: DateTime.utc(2020, 1, 1),
          model: 'm1',
        ),
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'return_object',
              arguments: '{"city":"SF",',
            ),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: '',
              arguments: '"temp":70}',
            ),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
        LLMFinishPart(
          const _FakeChatResponseWithFinishReason(
            finishReason: finishReason,
            usage: usage,
            providerMetadata: {
              'openai': {'id': 'resp_1'}
            },
          ),
          usage: usage,
          finishReason: finishReason,
        ),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      final partialFuture = result.partialObjectStream.toList();
      final textChunksFuture = result.textStream.toList();

      final partial = await partialFuture;
      expect(partial, isNotEmpty);
      expect(partial.last, containsPair('city', 'SF'));

      final textChunks = await textChunksFuture;
      expect(textChunks.join(), equals('{"city":"SF","temp":70}'));

      final text = await result.text;
      expect(text, equals('{"city":"SF","temp":70}'));

      final obj = await result.object;
      expect(obj, containsPair('city', 'SF'));
      expect(obj, containsPair('temp', 70));

      final resolvedWarnings = await result.warnings;
      expect(resolvedWarnings, equals(warnings));

      expect((await result.responseMetadata)?.id, equals('resp_1'));
      expect(
          (await result.requestMetadata)?.body,
          equals({
            'messages': ['hi']
          }));

      expect((await result.usage)?.totalTokens, equals(3));
      expect((await result.finishReason)?.unified,
          equals(LLMUnifiedFinishReason.stop));
      expect(await result.providerMetadata, contains('openai'));

      final finalResult = await result.finalResult;
      expect(finalResult.object, containsPair('city', 'SF'));
    });

    test('array output exposes elements and elementStream', () async {
      final model = _FakeStreamChatModel([
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'return_object',
              arguments: '{"elements":[{"city":"SF","temp":70},',
            ),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: '',
              arguments: '{"city":"LA","temp":80}]}',
            ),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
        output: StreamObjectOutput.array,
      );

      final elementsFromStream = await result.elementStream.toList();
      expect(elementsFromStream, hasLength(2));
      expect(elementsFromStream.first, containsPair('city', 'SF'));
      expect(elementsFromStream.last, containsPair('city', 'LA'));

      final elements = await result.elements;
      expect(elements, hasLength(2));
      expect(elements.first, containsPair('temp', 70));
      expect(elements.last, containsPair('temp', 80));

      final obj = await result.object;
      expect(obj, contains('elements'));
    });

    test('step boundaries reset stable result futures to last step', () async {
      final model = _FakeStreamChatModel([
        const LLMStepStartPart(0),
        const LLMResponseMetadataPart(
          id: 'resp_step_1',
          headers: {'x-step': '1'},
        ),
        const LLMToolInputStartPart(
          id: 'call_1',
          toolName: 'return_object',
        ),
        const LLMToolInputDeltaPart(id: 'call_1', delta: '{"city":"SF"}'),
        const LLMToolInputEndPart(id: 'call_1'),
        const LLMStepStartPart(1),
        const LLMResponseMetadataPart(
          id: 'resp_step_2',
          headers: {'x-step': '2'},
        ),
        const LLMToolInputStartPart(
          id: 'call_2',
          toolName: 'return_object',
        ),
        const LLMToolInputDeltaPart(id: 'call_2', delta: '{"city":"LA"}'),
        const LLMToolInputEndPart(id: 'call_2'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = StreamObjectResult.fromPartsStream(
        model.chatStreamParts([ChatMessage.user('hi')]),
        schema: schema,
        toolName: 'return_object',
      );

      final obj = await result.object;
      expect(obj, containsPair('city', 'LA'));

      final meta = await result.responseMetadata;
      expect(meta?.id, equals('resp_step_2'));
      expect(meta?.headers, containsPair('x-step', '2'));
    });

    test('fails when object does not match schema', () async {
      final model = _FakeStreamChatModel([
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'return_object',
              arguments: '{"temp":70}',
            ),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      expect(() async => await result.object, throwsA(isA<LLMError>()));
      expect(() async => await result.text, throwsA(isA<LLMError>()));
    });

    test('falls back to parsing a JSON object from text', () async {
      final model = _FakeStreamChatModel([
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Here: '),
        const LLMTextDeltaPart('{"city":"SF","temp":70}'),
        const LLMTextEndPart('Here: {"city":"SF","temp":70}'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      final textChunksFuture = result.textStream.toList();

      final textChunks = await textChunksFuture;
      expect(textChunks, isEmpty);

      final text = await result.text;
      expect(jsonDecode(text), containsPair('city', 'SF'));
      expect(jsonDecode(text), containsPair('temp', 70));

      final obj = await result.object;
      expect(obj, containsPair('city', 'SF'));
      expect(obj, containsPair('temp', 70));

      expect(await result.warnings, isEmpty);
    });

    test('emits best-effort partial objects only when valid JSON exists',
        () async {
      final model = _FakeStreamChatModel([
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'return_object',
              arguments: '{"city":"SF"',
            ),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: '',
              arguments: ',"temp":70}',
            ),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      final partial = await result.partialObjectStream.toList();
      expect(partial.map(jsonEncode).toList(),
          contains(jsonEncode({'city': 'SF', 'temp': 70})));
    });

    test('blocks when provider tool approval is required and stop is enabled',
        () async {
      final model = _ProviderApprovalObjectModel();

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
        stopOnProviderToolApprovalRequests: true,
      );

      final parts = await result.fullStream.toList();
      expect(model.calls, equals(1));

      final blocked = await result.providerToolApprovalBlockedState;
      expect(blocked, isNotNull);
      final blockedState = blocked!;

      expect(blockedState.stepIndex, equals(0));
      expect(blockedState.approvalRequests, hasLength(1));
      expect(blockedState.approvalRequests.single.approvalId, equals('apr_1'));

      expect((await result.finishReason)?.unified,
          equals(LLMUnifiedFinishReason.toolCalls));
      expect(await result.text, equals(''));
      expect(await result.object, equals(const <String, dynamic>{}));
      expect((await result.finalResult).object, isEmpty);
    });

    test('can resume after provider tool approval blocked state', () async {
      final model = _ProviderApprovalObjectModel();

      final initial = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
        stopOnProviderToolApprovalRequests: true,
      );

      await initial.fullStream.toList();
      final blocked = await initial.providerToolApprovalBlockedState;
      expect(blocked, isNotNull);

      final resumedParts = resumeChatPartsAfterProviderToolApprovalRequired(
        model: model,
        blockedState: blocked!,
        decisions: const [
          ToolApprovalDecision(
            approvalId: 'apr_1',
            approved: true,
          ),
        ],
        providerToolApprovalMaxSteps: 5,
      );

      final resumed = StreamObjectResult.fromPartsStream(
        resumedParts,
        schema: schema,
        toolName: 'return_object',
      );

      final partsFuture = resumed.fullStream.toList();

      final obj = await resumed.object;
      expect(obj, containsPair('city', 'SF'));
      expect(obj, containsPair('temp', 70));
      expect(model.calls, equals(2));

      final parts = await partsFuture;
      expect(
        parts.whereType<LLMStepStartPart>().map((p) => p.stepIndex).toList(),
        equals([1]),
      );
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
