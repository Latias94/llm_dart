import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/anthropic/mcp_models.dart';

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

final class _AnthropicChatResponseContentSupport {
  const _AnthropicChatResponseContentSupport();

  List<Map<String, dynamic>> contentBlocks(Map<String, dynamic> rawResponse) {
    final content = rawResponse['content'];
    if (content is! List || content.isEmpty) {
      return const [];
    }

    return [
      for (final block in content)
        if (block is Map<String, dynamic>)
          block
        else if (block is Map)
          Map<String, dynamic>.from(block),
    ];
  }

  String? extractText(Map<String, dynamic> rawResponse) {
    final textBlocks = contentBlocks(rawResponse)
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'])
        .whereType<String>();

    return textBlocks.isEmpty ? null : textBlocks.join('\n');
  }

  String? extractThinking(Map<String, dynamic> rawResponse) {
    final thinkingBlocks = <String>[];

    for (final block in contentBlocks(rawResponse)) {
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
}

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

final class _AnthropicChatResponseUsageSupport {
  const _AnthropicChatResponseUsageSupport();

  UsageInfo? extractUsage(Map<String, dynamic> rawResponse) {
    final usageData = _normalizeUsage(rawResponse['usage']);
    if (usageData == null) {
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

  Map<String, dynamic>? _normalizeUsage(Object? rawUsage) {
    if (rawUsage == null) {
      return null;
    }
    if (rawUsage is Map<String, dynamic>) {
      return rawUsage;
    }
    if (rawUsage is Map) {
      return Map<String, dynamic>.from(rawUsage);
    }
    return null;
  }
}
