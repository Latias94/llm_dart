part of 'anthropic_chat_response.dart';

final class _AnthropicChatResponseToolSupport {
  const _AnthropicChatResponseToolSupport();

  static const _contentSupport = _AnthropicChatResponseContentSupport();

  List<ToolCall>? extractToolCalls(Map<String, dynamic> rawResponse) {
    final toolCalls = <ToolCall>[
      for (final block in _blocksByType(rawResponse, 'tool_use'))
        ToolCall(
          id: block['id'] as String,
          callType: 'function',
          function: FunctionCall(
            name: block['name'] as String,
            arguments: jsonEncode(block['input']),
          ),
        ),
      for (final block in _blocksByType(rawResponse, 'mcp_tool_use'))
        ToolCall(
          id: block['id'] as String,
          callType: 'mcp_function',
          function: FunctionCall(
            name: block['name'] as String,
            arguments: jsonEncode(block['input']),
          ),
        ),
    ];

    return toolCalls.isEmpty ? null : toolCalls;
  }

  List<AnthropicMCPToolUse>? extractMcpToolUses(
    Map<String, dynamic> rawResponse,
  ) {
    final mcpToolUses = [
      for (final block in _blocksByType(rawResponse, 'mcp_tool_use'))
        AnthropicMCPToolUse.fromJson(block),
    ];

    return mcpToolUses.isEmpty ? null : mcpToolUses;
  }

  List<AnthropicMCPToolResult>? extractMcpToolResults(
    Map<String, dynamic> rawResponse,
  ) {
    final mcpToolResults = [
      for (final block in _blocksByType(rawResponse, 'mcp_tool_result'))
        AnthropicMCPToolResult.fromJson(block),
    ];

    return mcpToolResults.isEmpty ? null : mcpToolResults;
  }

  Iterable<Map<String, dynamic>> _blocksByType(
    Map<String, dynamic> rawResponse,
    String type,
  ) {
    return _contentSupport.contentBlocks(rawResponse).where(
          (block) => block['type'] == type,
        );
  }
}
