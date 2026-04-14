import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/anthropic/mcp_models.dart';

/// Anthropic chat response implementation.
class AnthropicChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;

  AnthropicChatResponse(this._rawResponse);

  @override
  String? get text {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final textBlocks = content
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String?)
        .where((text) => text != null)
        .cast<String>();

    return textBlocks.isEmpty ? null : textBlocks.join('\n');
  }

  @override
  String? get thinking {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final thinkingBlocks = <String>[];

    for (final block in content) {
      final blockType = block['type'] as String?;
      if (blockType == 'thinking') {
        final thinkingText = block['thinking'] as String?;
        if (thinkingText != null && thinkingText.isNotEmpty) {
          thinkingBlocks.add(thinkingText);
        }
      } else if (blockType == 'redacted_thinking') {
        thinkingBlocks
            .add('[Redacted thinking content - encrypted for safety]');
      }
    }

    return thinkingBlocks.isEmpty ? null : thinkingBlocks.join('\n\n');
  }

  @override
  List<ToolCall>? get toolCalls {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final toolCalls = <ToolCall>[];

    final toolUseBlocks =
        content.where((block) => block['type'] == 'tool_use').toList();

    for (final block in toolUseBlocks) {
      toolCalls.add(ToolCall(
        id: block['id'] as String,
        callType: 'function',
        function: FunctionCall(
          name: block['name'] as String,
          arguments: jsonEncode(block['input']),
        ),
      ));
    }

    final mcpToolUseBlocks =
        content.where((block) => block['type'] == 'mcp_tool_use').toList();

    for (final block in mcpToolUseBlocks) {
      toolCalls.add(ToolCall(
        id: block['id'] as String,
        callType: 'mcp_function',
        function: FunctionCall(
          name: block['name'] as String,
          arguments: jsonEncode(block['input']),
        ),
      ));
    }

    return toolCalls.isEmpty ? null : toolCalls;
  }

  /// Get Anthropic MCP tool use blocks from the response.
  List<AnthropicMCPToolUse>? get mcpToolUses {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final mcpToolUseBlocks =
        content.where((block) => block['type'] == 'mcp_tool_use').toList();

    if (mcpToolUseBlocks.isEmpty) return null;

    return mcpToolUseBlocks
        .map((block) => AnthropicMCPToolUse.fromJson(block))
        .toList();
  }

  /// Get Anthropic MCP tool result blocks from the response.
  List<AnthropicMCPToolResult>? get mcpToolResults {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final mcpToolResultBlocks =
        content.where((block) => block['type'] == 'mcp_tool_result').toList();

    if (mcpToolResultBlocks.isEmpty) return null;

    return mcpToolResultBlocks
        .map((block) => AnthropicMCPToolResult.fromJson(block))
        .toList();
  }

  @override
  UsageInfo? get usage {
    final rawUsage = _rawResponse['usage'];
    if (rawUsage == null) return null;

    final Map<String, dynamic> usageData;
    if (rawUsage is Map<String, dynamic>) {
      usageData = rawUsage;
    } else if (rawUsage is Map) {
      usageData = Map<String, dynamic>.from(rawUsage);
    } else {
      return null;
    }

    final inputTokens = usageData['input_tokens'] as int? ?? 0;
    final outputTokens = usageData['output_tokens'] as int? ?? 0;

    return UsageInfo(
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: inputTokens + outputTokens,
      reasoningTokens: null,
    );
  }

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
