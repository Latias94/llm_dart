import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('collectToolApprovalsFromPrompt', () {
    test('returns empty when last message is not tool role', () {
      final prompt = Prompt(
        messages: [
          PromptMessage.user('hi'),
        ],
      );

      final collected = collectToolApprovalsFromPrompt(prompt);
      expect(collected.approved, isEmpty);
      expect(collected.denied, isEmpty);
    });

    test('collects approved tool approvals from last tool message', () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.assistant,
            parts: const [
              ToolCallPart(
                toolCallId: 'call-1',
                toolName: 'tool1',
                input: {'value': 'test-input'},
              ),
              ToolApprovalRequestPart(
                approvalId: 'approval-id-1',
                toolCallId: 'call-1',
              ),
            ],
          ),
          PromptMessage(
            role: PromptRole.tool,
            parts: const [
              ToolApprovalResponsePart(
                approvalId: 'approval-id-1',
                approved: true,
              ),
            ],
          ),
        ],
      );

      final collected = collectToolApprovalsFromPrompt(prompt);
      expect(collected.approved, hasLength(1));
      expect(collected.denied, isEmpty);

      final item = collected.approved.single;
      expect(item.approvalRequest.approvalId, equals('approval-id-1'));
      expect(item.approvalResponse.approved, isTrue);
      expect(item.toolCall.toolCallId, equals('call-1'));
    });

    test('collects denied tool approvals', () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.assistant,
            parts: const [
              ToolCallPart(
                toolCallId: 'call-1',
                toolName: 'tool1',
                input: {'value': 'test-input'},
              ),
              ToolApprovalRequestPart(
                approvalId: 'approval-id-1',
                toolCallId: 'call-1',
              ),
            ],
          ),
          PromptMessage(
            role: PromptRole.tool,
            parts: const [
              ToolApprovalResponsePart(
                approvalId: 'approval-id-1',
                approved: false,
                reason: 'no',
              ),
            ],
          ),
        ],
      );

      final collected = collectToolApprovalsFromPrompt(prompt);
      expect(collected.approved, isEmpty);
      expect(collected.denied, hasLength(1));
      expect(collected.denied.single.approvalResponse.reason, equals('no'));
    });

    test('skips approvals that already have tool results in last tool message',
        () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.assistant,
            parts: const [
              ToolCallPart(
                toolCallId: 'call-1',
                toolName: 'tool1',
                input: {'value': 'test-input'},
              ),
              ToolApprovalRequestPart(
                approvalId: 'approval-id-1',
                toolCallId: 'call-1',
              ),
            ],
          ),
          PromptMessage(
            role: PromptRole.tool,
            parts: const [
              ToolResultPart(
                'call-1',
                'tool1',
                ToolResultTextOutput('ok'),
              ),
              ToolApprovalResponsePart(
                approvalId: 'approval-id-1',
                approved: true,
              ),
            ],
          ),
        ],
      );

      final collected = collectToolApprovalsFromPrompt(prompt);
      expect(collected.approved, isEmpty);
      expect(collected.denied, isEmpty);
    });

    test('throws when approval response has no matching request', () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.assistant,
            parts: const [
              ToolCallPart(
                toolCallId: 'call-1',
                toolName: 'tool1',
                input: {'value': 'test-input'},
              ),
            ],
          ),
          PromptMessage(
            role: PromptRole.tool,
            parts: const [
              ToolApprovalResponsePart(
                approvalId: 'approval-id-1',
                approved: true,
              ),
            ],
          ),
        ],
      );

      expect(
        () => collectToolApprovalsFromPrompt(prompt),
        throwsA(isA<InvalidToolApprovalError>()),
      );
    });
  });
}
