import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 prompt codec: tool messages', () {
    test('encodes ToolResultPart as role=tool message', () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const ToolResultPart(
                'call_1',
                'tool',
                ToolResultTextOutput('ok'),
              ),
            ],
          ),
        ],
      );

      final encoded = encodeV3Prompt(prompt);
      expect(encoded, hasLength(1));
      expect(encoded.single['role'], 'tool');
      expect((encoded.single['content'] as List).single, {
        'type': 'tool-result',
        'toolCallId': 'call_1',
        'toolName': 'tool',
        'output': {'type': 'text', 'value': 'ok'},
      });
    });

    test('decodes role=tool tool-result into ToolResultPart', () {
      final prompt = decodeV3Prompt([
        {
          'role': 'tool',
          'content': [
            {
              'type': 'tool-result',
              'toolCallId': 'call_1',
              'toolName': 'tool',
              'output': {'type': 'text', 'value': 'ok'},
            }
          ],
        }
      ]);

      expect(prompt.messages, hasLength(1));
      expect(prompt.messages.single.role, PromptRole.tool);
      expect(prompt.messages.single.parts.single, isA<ToolResultPart>());
    });

    test('invalid tool-result output throws', () {
      expect(
        () => decodeV3Prompt([
          {
            'role': 'tool',
            'content': [
              {
                'type': 'tool-result',
                'toolCallId': 'call_1',
                'toolName': 'tool',
                'output': {'type': 'text'},
              }
            ],
          }
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('encodes ToolApprovalResponsePart as role=tool message', () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: const [
              ToolApprovalResponsePart(
                approvalId: 'appr_1',
                approved: true,
                reason: 'ok',
              ),
            ],
          ),
        ],
      );

      final encoded = encodeV3Prompt(prompt);
      expect(encoded, hasLength(1));
      expect(encoded.single['role'], 'tool');
      expect((encoded.single['content'] as List).single, {
        'type': 'tool-approval-response',
        'approvalId': 'appr_1',
        'approved': true,
        'reason': 'ok',
      });
    });

    test(
        'decodes role=tool tool-approval-response into ToolApprovalResponsePart',
        () {
      final prompt = decodeV3Prompt([
        {
          'role': 'tool',
          'content': [
            {
              'type': 'tool-approval-response',
              'approvalId': 'appr_1',
              'approved': false,
              'reason': 'no',
            }
          ],
        }
      ]);

      expect(
          prompt.messages.single.parts.single, isA<ToolApprovalResponsePart>());
    });

    test('groups consecutive tool parts into one tool message', () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const ToolResultPart(
                'call_1',
                'tool',
                ToolResultTextOutput('ok'),
              ),
              const ToolApprovalResponsePart(
                approvalId: 'appr_1',
                approved: true,
              ),
            ],
          ),
        ],
      );

      final encoded = encodeV3Prompt(prompt);
      expect(encoded, hasLength(1));
      expect(encoded.single['role'], 'tool');
      expect(encoded.single['content'], [
        {
          'type': 'tool-result',
          'toolCallId': 'call_1',
          'toolName': 'tool',
          'output': {'type': 'text', 'value': 'ok'},
        },
        {
          'type': 'tool-approval-response',
          'approvalId': 'appr_1',
          'approved': true,
        },
      ]);
    });

    test('encodes ToolApprovalRequestPart as assistant content part', () {
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
        ],
      );

      final encoded = encodeV3Prompt(prompt);
      expect(encoded, hasLength(1));
      expect(encoded.single['role'], 'assistant');
      expect(encoded.single['content'], [
        {
          'type': 'tool-call',
          'toolCallId': 'call-1',
          'toolName': 'tool1',
          'input': {'value': 'test-input'},
        },
        {
          'type': 'tool-approval-request',
          'approvalId': 'approval-id-1',
          'toolCallId': 'call-1',
        },
      ]);
    });

    test('decodes assistant tool-approval-request into ToolApprovalRequestPart',
        () {
      final prompt = decodeV3Prompt([
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'tool-approval-request',
              'approvalId': 'approval-id-1',
              'toolCallId': 'call-1',
            },
          ],
        },
      ]);

      expect(prompt.messages, hasLength(1));
      expect(prompt.messages.single.role, PromptRole.assistant);
      expect(
          prompt.messages.single.parts.single, isA<ToolApprovalRequestPart>());
    });
  });
}
