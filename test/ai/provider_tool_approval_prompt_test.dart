import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('appendProviderToolApprovalsToPrompt', () {
    test('appends assistant tool call + tool approval responses', () {
      final base = Prompt(
        messages: [
          PromptMessage.user('hi'),
        ],
      );

      final prompt = appendProviderToolApprovalsToPrompt(
        base,
        assistantText: 'ok',
        providerToolCalls: const [
          LLMProviderToolCallPart(
            toolCallId: 'call_1',
            toolName: 'mcp.web_search',
            input: {'q': 'hello'},
            providerExecuted: true,
          ),
        ],
        decisions: const [
          ToolApprovalDecision(
            approvalId: 'apr_1',
            approved: true,
            reason: 'allow',
          ),
        ],
      );

      expect(prompt.messages, hasLength(3));
      expect(prompt.messages[1].role, equals(PromptRole.assistant));
      expect(prompt.messages[2].role, equals(PromptRole.tool));

      final assistantParts = prompt.messages[1].parts;
      expect(assistantParts.whereType<TextPart>(), hasLength(1));
      expect(assistantParts.whereType<ToolCallPart>(), hasLength(1));
      final toolCall = assistantParts.whereType<ToolCallPart>().single;
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCallId, equals('call_1'));

      final toolParts = prompt.messages[2].parts;
      expect(toolParts.whereType<ToolApprovalResponsePart>(), hasLength(1));
      final approval = toolParts.whereType<ToolApprovalResponsePart>().single;
      expect(approval.approvalId, equals('apr_1'));
      expect(approval.approved, isTrue);
      expect(approval.reason, equals('allow'));
    });
  });
}
