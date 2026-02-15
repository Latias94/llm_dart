import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _Resp implements ChatResponseWithFinishReason {
  @override
  final String? text;

  @override
  final LLMFinishReason? finishReason;

  const _Resp({this.text, this.finishReason});

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _ProviderApprovalModel extends ChatCapability
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
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    calls++;

    if (calls == 1) {
      yield const LLMStreamStartPart();
      yield const LLMProviderToolCallPart(
        toolCallId: 'call_1',
        toolName: 'mcp.web_search',
        input: {'q': 'hello'},
        providerExecuted: true,
      );
      yield const LLMProviderToolApprovalRequestPart(
        approvalId: 'apr_1',
        toolCallId: 'call_1',
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
      yield const LLMTextDeltaPart('ok', blockId: '1');
      yield LLMFinishPart(
        const _Resp(
          text: 'ok',
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
  group('Provider tool approval loop', () {
    test('blocks when provider tool approval is required and no handler',
        () async {
      final model = _ProviderApprovalModel();

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        stopOnProviderToolApprovalRequests: true,
        providerToolApprovalMaxSteps: 5,
      );

      final parts = await result.fullStream.toList();
      expect(model.calls, equals(1));
      expect(
          parts.whereType<LLMProviderToolApprovalRequestPart>(), hasLength(1));

      final blocked = await result.providerToolApprovalBlockedState;
      expect(blocked, isNotNull);
      final state = blocked!;

      expect(state.stepIndex, equals(0));
      expect(state.approvalRequests, hasLength(1));
      expect(state.approvalRequests.single.approvalId, equals('apr_1'));
      expect(state.prompt.messages, isNotEmpty);

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.finishReason?.unified, LLMUnifiedFinishReason.toolCalls);
      expect(await result.finishReason, isNotNull);
    });

    test('resumes streaming after provider tool approval', () async {
      final model = _ProviderApprovalModel();

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        onProviderToolApprovalRequests: (requests) async {
          expect(requests, hasLength(1));
          expect(requests.single.approvalId, equals('apr_1'));
          return const [
            ToolApprovalDecision(
              approvalId: 'apr_1',
              approved: true,
            ),
          ];
        },
        providerToolApprovalMaxSteps: 5,
      );

      final partsFuture = result.fullStream.toList();

      expect(await result.text, equals('ok'));
      expect(await result.finishReason, isNotNull);
      expect(model.calls, equals(2));

      final parts = await partsFuture;
      expect(
          parts.whereType<LLMProviderToolApprovalRequestPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));

      final stepStarts =
          parts.whereType<LLMStepStartPart>().map((p) => p.stepIndex).toList();
      expect(stepStarts, equals([0, 1]));
    });

    test('can resume from blocked state with explicit decisions', () async {
      final model = _ProviderApprovalModel();

      final initial = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        stopOnProviderToolApprovalRequests: true,
        providerToolApprovalMaxSteps: 5,
      );

      await initial.fullStream.toList();
      final blocked = await initial.providerToolApprovalBlockedState;
      expect(blocked, isNotNull);

      final resumed = resumeStreamTextAfterProviderToolApprovalBlocked(
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
      final partsFuture = resumed.fullStream.toList();

      expect(await resumed.text, equals('ok'));
      expect(model.calls, equals(2));

      final parts = await partsFuture;
      expect(
          parts.whereType<LLMStepStartPart>().map((p) => p.stepIndex).toList(),
          equals([1]));
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });

    test(
        'toolSet blocks when provider tool approval is required and stop is enabled',
        () async {
      final model = _ProviderApprovalModel();
      final toolSet = ToolSet(const <LocalTool>[]);

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolSet: toolSet,
        stopOnProviderToolApprovalRequests: true,
        providerToolApprovalMaxSteps: 5,
      );

      final parts = await result.fullStream.toList();
      expect(model.calls, equals(1));
      expect(
        parts.whereType<LLMProviderToolApprovalRequestPart>(),
        hasLength(1),
      );

      final blocked = await result.providerToolApprovalBlockedState;
      expect(blocked, isNotNull);
      expect(blocked!.approvalRequests.single.approvalId, equals('apr_1'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.finishReason?.unified, LLMUnifiedFinishReason.toolCalls);
    });

    test('toolSet can resume after provider tool approval blocked state',
        () async {
      final model = _ProviderApprovalModel();
      final toolSet = ToolSet(const <LocalTool>[]);

      final initial = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolSet: toolSet,
        stopOnProviderToolApprovalRequests: true,
        providerToolApprovalMaxSteps: 5,
      );

      await initial.fullStream.toList();
      final blocked = await initial.providerToolApprovalBlockedState;
      expect(blocked, isNotNull);

      final resumed = resumeStreamTextToolLoopAfterProviderToolApprovalBlocked(
        model: model,
        blockedState: blocked!,
        decisions: const [
          ToolApprovalDecision(
            approvalId: 'apr_1',
            approved: true,
          ),
        ],
        toolSet: toolSet,
        providerToolApprovalMaxSteps: 5,
      );

      final partsFuture = resumed.fullStream.toList();
      expect(await resumed.text, equals('ok'));
      expect(model.calls, equals(2));

      final parts = await partsFuture;
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
