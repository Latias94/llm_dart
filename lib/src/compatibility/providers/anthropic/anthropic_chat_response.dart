import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/anthropic/mcp_models.dart';

part 'anthropic_chat_response_content_support.dart';
part 'anthropic_chat_response_tool_support.dart';
part 'anthropic_chat_response_usage_support.dart';

/// Anthropic chat response implementation.
class AnthropicChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  AnthropicChatResponse(this._rawResponse);

  static const _contentSupport = _AnthropicChatResponseContentSupport();
  static const _toolSupport = _AnthropicChatResponseToolSupport();
  static const _usageSupport = _AnthropicChatResponseUsageSupport();

  @override
  String? get text => _contentSupport.extractText(_rawResponse);

  @override
  String? get thinking => _contentSupport.extractThinking(_rawResponse);

  @override
  List<ToolCall>? get toolCalls => _toolSupport.extractToolCalls(_rawResponse);

  /// Get Anthropic MCP tool use blocks from the response.
  List<AnthropicMCPToolUse>? get mcpToolUses =>
      _toolSupport.extractMcpToolUses(_rawResponse);

  /// Get Anthropic MCP tool result blocks from the response.
  List<AnthropicMCPToolResult>? get mcpToolResults =>
      _toolSupport.extractMcpToolResults(_rawResponse);

  @override
  UsageInfo? get usage => _usageSupport.extractUsage(_rawResponse);

  @override
  String toString() {
    final textContent = text;
    final calls = toolCalls;
    final thinkingContent = thinking;

    final parts = <String>[];

    if (thinkingContent != null) {
      parts.add('Thinking: $thinkingContent');
    }

    if (calls != null) {
      parts.add(calls.map((call) => call.toString()).join('\n'));
    }

    if (textContent != null) {
      parts.add(textContent);
    }

    return parts.join('\n');
  }
}
