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
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
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
  group('Agent.streamText deferred provider-tool options', () {
    test('waitForDeferredProviderToolResults=true triggers an extra step',
        () async {
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
          const LLMFinishPart(_FakeChatResponse(text: 'Done')),
        ],
      ]);

      final agent = Agent(model: model);

      final parts = await agent
          .streamText(
            messages: [ChatMessage.user('hi')],
            onProviderToolApprovalRequests: (_) async => const [],
            waitForDeferredProviderToolResults: true,
            maxAdditionalProviderToolResultSteps: 1,
          )
          .fullStream
          .toList();

      expect(model.prompts, hasLength(2));
      expect(parts.whereType<LLMProviderToolCallPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolResultPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>().single.response.text, 'Done');
    });

    test('maxAdditionalProviderToolResultSteps=0 prevents extra step',
        () async {
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
          const LLMFinishPart(_FakeChatResponse(text: 'Done')),
        ],
      ]);

      final agent = Agent(model: model);

      final parts = await agent
          .streamText(
            messages: [ChatMessage.user('hi')],
            onProviderToolApprovalRequests: (_) async => const [],
            waitForDeferredProviderToolResults: true,
            maxAdditionalProviderToolResultSteps: 0,
          )
          .fullStream
          .toList();

      expect(model.prompts, hasLength(1));
      expect(parts.whereType<LLMProviderToolCallPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolResultPart>(), isEmpty);
      expect(parts.whereType<LLMFinishPart>().single.response.text, 'Done');
    });
  });
}
