import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _NoopPromptModel extends ChatCapability implements PromptChatCapability {
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    throw StateError('chatWithTools should not be called in this test');
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    return _TextResponse('ok');
  }
}

class _TextResponse extends ChatResponse {
  final String value;
  _TextResponse(this.value);

  @override
  String? get text => value;

  @override
  List<ToolCall>? get toolCalls => null;
}

void main() {
  group('MissingToolResultsError', () {
    test('throws when tool-call has no tool-result before user/system message',
        () async {
      final model = _NoopPromptModel();

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: PromptRole.assistant,
            parts: [
              ToolCallPart(
                toolCallId: 'call_1',
                toolName: 'get_weather',
                input: {'location': 'SF'},
              ),
            ],
          ),
          PromptMessage.user('continue'),
        ],
      );

      await expectLater(
        generateText(model: model, promptIr: prompt),
        throwsA(isA<MissingToolResultsError>()),
      );
    });

    test('does not throw when tool-result is present', () async {
      final model = _NoopPromptModel();

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: PromptRole.assistant,
            parts: [
              ToolCallPart(
                toolCallId: 'call_1',
                toolName: 'get_weather',
                input: {'location': 'SF'},
              ),
            ],
          ),
          const PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolResultPart(
                'call_1',
                'get_weather',
                ToolResultJsonOutput({'temp': 20}),
              ),
            ],
          ),
          PromptMessage.user('continue'),
        ],
      );

      final result = await generateText(model: model, promptIr: prompt);
      expect(result.text, equals('ok'));
    });

    test('does not throw when tool-call is acked by tool approval response',
        () async {
      final model = _NoopPromptModel();

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: PromptRole.assistant,
            parts: [
              ToolCallPart(
                toolCallId: 'call_1',
                toolName: 'dangerous_tool',
                input: {'x': 1},
              ),
              ToolApprovalRequestPart(
                approvalId: 'approval_1',
                toolCallId: 'call_1',
              ),
            ],
          ),
          const PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolApprovalResponsePart(
                approvalId: 'approval_1',
                approved: false,
                reason: 'no',
              ),
            ],
          ),
          PromptMessage.user('continue'),
        ],
      );

      final result = await generateText(model: model, promptIr: prompt);
      expect(result.text, equals('ok'));
    });
  });
}
