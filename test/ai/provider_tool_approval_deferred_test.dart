library;

import 'package:llm_dart_ai/src/provider_tool_approval_loop.dart';
import 'package:llm_dart_ai/src/prompt_input.dart';
import 'package:llm_dart_ai/src/types.dart';
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
    Map<String, dynamic>? providerMetadata,
  })  : thinking = null,
        toolCalls = null,
        usage = null,
        _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _SequencedPromptStreamModel extends ChatCapability
    implements PromptChatStreamPartsCapability {
  final List<List<LLMStreamPart>> steps;

  _SequencedPromptStreamModel(this.steps);

  final prompts = <Prompt>[];
  var _index = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    prompts.add(prompt);
    if (_index >= steps.length) {
      throw StateError('No more prompt stream steps configured for fake model');
    }
    final parts = steps[_index++];
    for (final part in parts) {
      yield part;
    }
  }
}

void main() {
  group('streamChatPartsWithProviderToolApprovals (deferred)', () {
    test('continues until deferred provider tool result arrives', () async {
      final model = _SequencedPromptStreamModel([
        [
          const LLMStreamStartPart(),
          const LLMProviderToolCallPart(
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            input: {'code': 'print("hi")'},
            providerExecuted: true,
            supportsDeferredResults: true,
          ),
          const LLMFinishPart(_FakeChatResponse()),
        ],
        [
          const LLMStreamStartPart(),
          const LLMProviderToolResultPart(
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            result: {'ok': true},
          ),
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(_FakeChatResponse(text: 'Done')),
        ],
      ]);

      final parts = await streamChatPartsWithProviderToolApprovals(
        model: model,
        input: StandardizedChatMessages([ChatMessage.user('hi')]),
        tools: null,
        callOptions: const LLMCallOptions(),
        maxSteps: 5,
      ).toList();

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(parts.whereType<LLMStepStartPart>(), hasLength(2));
      expect(parts.whereType<LLMStepFinishPart>(), hasLength(2));
      expect(parts.whereType<LLMProviderToolCallPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolResultPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>().single.response.text,
          equals('Done'));

      expect(model.prompts, hasLength(2));
      final step1Prompt = model.prompts[1];
      final toolCallParts = step1Prompt.messages
          .where((m) => m.role == PromptRole.assistant)
          .expand((m) => m.parts)
          .whereType<ToolCallPart>()
          .where((p) => p.toolCallId == 'prov_1')
          .toList(growable: false);
      expect(toolCallParts, hasLength(1));
      expect(toolCallParts.single.toolName, equals('code_execution'));
    });

    test('approval flow continues and observes deferred tool result', () async {
      final model = _SequencedPromptStreamModel([
        [
          const LLMStreamStartPart(),
          const LLMProviderToolCallPart(
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            input: {'code': 'print("hi")'},
            providerExecuted: true,
            supportsDeferredResults: true,
          ),
          const LLMProviderToolApprovalRequestPart(
            approvalId: 'a_1',
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            input: {'code': 'print("hi")'},
          ),
          const LLMFinishPart(_FakeChatResponse()),
        ],
        [
          const LLMStreamStartPart(),
          const LLMProviderToolResultPart(
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            result: {'ok': true},
          ),
          const LLMFinishPart(_FakeChatResponse(text: 'Done')),
        ],
      ]);

      final parts = await streamChatPartsWithProviderToolApprovals(
        model: model,
        input: StandardizedChatMessages([ChatMessage.user('hi')]),
        tools: null,
        callOptions: const LLMCallOptions(),
        onApprovalRequests: (requests) async {
          return requests
              .map(
                (r) => ToolApprovalDecision(
                  approvalId: r.approvalId,
                  approved: true,
                ),
              )
              .toList(growable: false);
        },
        maxSteps: 5,
      ).toList();

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(
          parts.whereType<LLMProviderToolApprovalRequestPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolResultPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>().single.response.text,
          equals('Done'));

      expect(model.prompts, hasLength(2));
      final afterApprovalPrompt = model.prompts[1];
      final approvalResponses = afterApprovalPrompt.messages
          .where((m) => m.role == PromptRole.tool)
          .expand((m) => m.parts)
          .whereType<ToolApprovalResponsePart>()
          .where((p) => p.approvalId == 'a_1')
          .toList(growable: false);
      expect(approvalResponses, hasLength(1));
      expect(approvalResponses.single.approved, isTrue);
    });
  });
}
