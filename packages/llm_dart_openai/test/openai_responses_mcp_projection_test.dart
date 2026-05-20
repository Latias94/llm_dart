import 'package:llm_dart_openai/src/responses/openai_responses_mcp_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses MCP projection', () {
    test('projects approval requests into provider-executed tool calls', () {
      final projection = projectOpenAIResponsesMcpApprovalRequest({
        'id': 'approval_item_1',
        'type': 'mcp_approval_request',
        'approval_request_id': 'approval_1',
        'name': 'create_short_url',
        'server_label': 'zip1',
        'arguments': '{"url":"https://example.com"}',
      });

      expect(projection, isNotNull);
      expect(projection!.approvalId, 'approval_1');
      expect(projection.qualifiedToolName, 'mcp.create_short_url');
      expect(projection.input, {
        'url': 'https://example.com',
      });

      final toolCall = projection.toToolCall();
      expect(toolCall.toolCallId, 'approval_1');
      expect(toolCall.toolName, 'mcp.create_short_url');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.isDynamic, isTrue);
      expect(toolCall.title, 'zip1');

      final approval = projection.toApprovalRequest();
      expect(approval.approvalId, 'approval_1');
      expect(approval.toolCallId, 'approval_1');
      expect(projection.providerMetadata?['openai'], {
        'itemId': 'approval_item_1',
        'itemType': 'mcp_approval_request',
        'approvalRequestId': 'approval_1',
        'serverLabel': 'zip1',
      });
    });

    test('projects MCP call outputs with error state', () {
      final projection = projectOpenAIResponsesMcpCall({
        'id': 'mcp_call_1',
        'type': 'mcp_call',
        'approval_request_id': 'approval_1',
        'name': 'create_short_url',
        'server_label': 'zip1',
        'arguments': '{"url":"https://example.com"}',
        'error': {
          'message': 'denied',
        },
      });

      expect(projection, isNotNull);
      expect(projection!.toolCallId, 'approval_1');
      expect(projection.qualifiedToolName, 'mcp.create_short_url');

      final toolResult = projection.toToolResult();
      expect(toolResult.toolCallId, 'approval_1');
      expect(toolResult.toolName, 'mcp.create_short_url');
      expect(toolResult.isDynamic, isTrue);
      expect(toolResult.toolOutput, isA<ErrorJsonToolOutput>());
      expect(toolResult.output, {
        'type': 'mcp_call',
        'serverLabel': 'zip1',
        'name': 'create_short_url',
        'arguments': {
          'url': 'https://example.com',
        },
        'error': {
          'message': 'denied',
        },
      });
      expect(projection.providerMetadata?['openai'], {
        'itemId': 'mcp_call_1',
        'itemType': 'mcp_call',
        'approvalRequestId': 'approval_1',
        'serverLabel': 'zip1',
      });
    });

    test('returns null for incomplete MCP items', () {
      expect(
        projectOpenAIResponsesMcpApprovalRequest({
          'type': 'mcp_approval_request',
          'name': 'missing_id',
        }),
        isNull,
      );
      expect(
        projectOpenAIResponsesMcpCall({
          'id': 'mcp_call_1',
          'type': 'mcp_call',
        }),
        isNull,
      );
    });
  });
}
