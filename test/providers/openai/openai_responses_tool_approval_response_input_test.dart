import 'package:test/test.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/responses.dart';

void main() {
  group('OpenAI Responses tool approval response input', () {
    test(
        'encodes ToolApprovalResponsePart into item_reference + mcp_approval_response when store=true',
        () {
      final prompt = Prompt(
        messages: const [
          PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolApprovalResponsePart(
                approvalId: 'mcpr_123',
                approved: true,
                reason: 'ok',
              ),
            ],
          ),
        ],
      );

      final input =
          OpenAIResponsesMessageConverter.buildInputMessagesFromPrompt(
        prompt,
        store: true,
      );

      expect(input, [
        {'type': 'item_reference', 'id': 'mcpr_123'},
        {
          'type': 'mcp_approval_response',
          'approval_request_id': 'mcpr_123',
          'approve': true,
        },
      ]);
    });

    test(
        'encodes ToolApprovalResponsePart into mcp_approval_response only when store=false',
        () {
      final prompt = Prompt(
        messages: const [
          PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolApprovalResponsePart(
                approvalId: 'mcpr_123',
                approved: false,
              ),
            ],
          ),
        ],
      );

      final input =
          OpenAIResponsesMessageConverter.buildInputMessagesFromPrompt(
        prompt,
        store: false,
      );

      expect(input, [
        {
          'type': 'mcp_approval_response',
          'approval_request_id': 'mcpr_123',
          'approve': false,
        },
      ]);
    });

    test(
        'skips duplicate ToolApprovalResponsePart with same approvalId across the prompt',
        () {
      final prompt = Prompt(
        messages: const [
          PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolApprovalResponsePart(
                approvalId: 'mcpr_dup',
                approved: true,
              ),
            ],
          ),
          PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolApprovalResponsePart(
                approvalId: 'mcpr_dup',
                approved: false,
              ),
            ],
          ),
        ],
      );

      final input =
          OpenAIResponsesMessageConverter.buildInputMessagesFromPrompt(
        prompt,
        store: true,
      );

      expect(input, [
        {'type': 'item_reference', 'id': 'mcpr_dup'},
        {
          'type': 'mcp_approval_response',
          'approval_request_id': 'mcpr_dup',
          'approve': true,
        },
      ]);
    });

    test('preserves ordering when mixed with user text parts', () {
      final prompt = Prompt(
        messages: const [
          PromptMessage(role: PromptRole.user, parts: [TextPart('before')]),
          PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolApprovalResponsePart(
                approvalId: 'mcpr_1',
                approved: true,
              ),
            ],
          ),
          PromptMessage(role: PromptRole.user, parts: [TextPart('after')]),
        ],
      );

      final input =
          OpenAIResponsesMessageConverter.buildInputMessagesFromPrompt(
        prompt,
        store: true,
      );

      expect(input, [
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': 'before'}
          ],
        },
        {'type': 'item_reference', 'id': 'mcpr_1'},
        {
          'type': 'mcp_approval_response',
          'approval_request_id': 'mcpr_1',
          'approve': true,
        },
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': 'after'}
          ],
        },
      ]);
    });

    test('rejects empty approvalId', () {
      final prompt = Prompt(
        messages: const [
          PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolApprovalResponsePart(
                approvalId: '',
                approved: true,
              ),
            ],
          ),
        ],
      );

      expect(
        () => OpenAIResponsesMessageConverter.buildInputMessagesFromPrompt(
          prompt,
          store: true,
        ),
        throwsA(isA<InvalidRequestError>()),
      );
    });
  });
}
