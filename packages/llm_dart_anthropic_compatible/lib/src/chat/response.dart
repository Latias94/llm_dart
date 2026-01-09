part of 'package:llm_dart_anthropic_compatible/chat.dart';

/// Anthropic chat response implementation.
class AnthropicChatResponse implements ChatResponseWithAssistantMessage {
  final Map<String, dynamic> _rawResponse;
  final String? _providerId;
  final ToolNameMapping? _toolNameMapping;

  AnthropicChatResponse(this._rawResponse,
      [this._providerId, this._toolNameMapping]);

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

    // Collect all thinking blocks (including redacted thinking)
    final thinkingBlocks = <String>[];

    for (final block in content) {
      final blockType = block['type'] as String?;
      if (blockType == 'thinking') {
        final thinkingText = block['thinking'] as String?;
        if (thinkingText != null && thinkingText.isNotEmpty) {
          thinkingBlocks.add(thinkingText);
        }
      } else if (blockType == 'redacted_thinking') {
        // For redacted thinking, we can't show the content but we can indicate it exists.
        // The actual encrypted data is in the 'data' field but should not be displayed.
        thinkingBlocks
            .add('[Redacted thinking content - encrypted for safety]');
      }
    }

    return thinkingBlocks.isEmpty ? null : thinkingBlocks.join('\n\n');
  }

  @override
  Map<String, dynamic>? get providerMetadata {
    final id = _rawResponse['id'];
    final model = _rawResponse['model'];
    final stopReason = _rawResponse['stop_reason'];
    final rawUsage = _rawResponse['usage'];
    final container = _rawResponse['container'];

    if (id == null &&
        model == null &&
        stopReason == null &&
        rawUsage == null &&
        container == null) {
      return null;
    }

    final Map<String, dynamic>? usage;
    if (rawUsage is Map<String, dynamic>) {
      usage = rawUsage;
    } else if (rawUsage is Map) {
      usage = Map<String, dynamic>.from(rawUsage);
    } else {
      usage = null;
    }

    final serverToolUseRaw = usage?['server_tool_use'];
    final Map<String, dynamic>? serverToolUse;
    if (serverToolUseRaw is Map<String, dynamic>) {
      serverToolUse = serverToolUseRaw;
    } else if (serverToolUseRaw is Map) {
      serverToolUse = Map<String, dynamic>.from(serverToolUseRaw);
    } else {
      serverToolUse = null;
    }

    final rawProviderId = _providerId?.trim();
    final providerId = rawProviderId != null && rawProviderId.isNotEmpty
        ? rawProviderId
        : 'anthropic';
    final payload = <String, dynamic>{
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      if (stopReason != null) 'stopReason': stopReason,
      if (stopReason != null) 'finishReason': stopReason,
      if (usage != null)
        'usage': {
          if (usage['input_tokens'] != null)
            'inputTokens': usage['input_tokens'],
          if (usage['output_tokens'] != null)
            'outputTokens': usage['output_tokens'],
          if (usage['cache_creation_input_tokens'] != null)
            'cacheCreationInputTokens': usage['cache_creation_input_tokens'],
          if (usage['cache_read_input_tokens'] != null)
            'cacheReadInputTokens': usage['cache_read_input_tokens'],
          if (usage['service_tier'] != null)
            'serviceTier': usage['service_tier'],
          if (serverToolUse != null)
            'serverToolUse': {
              if (serverToolUse['web_search_requests'] != null)
                'webSearchRequests': serverToolUse['web_search_requests'],
              if (serverToolUse['web_fetch_requests'] != null)
                'webFetchRequests': serverToolUse['web_fetch_requests'],
            },
        },
      if (container != null) 'container': container,
    };

    return {
      providerId: payload,
      '$providerId.messages': payload,
    };
  }

  @override
  List<ToolCall>? get toolCalls {
    final content = _rawResponse['content'] as List?;
    if (content == null || content.isEmpty) return null;

    final toolCalls = <ToolCall>[];

    // Handle regular tool_use blocks.
    final toolUseBlocks =
        content.where((block) => block['type'] == 'tool_use').toList();

    for (final block in toolUseBlocks) {
      final requestName = block['name'] as String?;
      if (requestName == null) {
        continue;
      }

      // Provider-native tools are executed server-side; do not expose them as
      // local tool calls.
      final isProviderNativeTool =
          _toolNameMapping?.providerToolIdForRequestName(requestName) != null ||
              requestName == 'web_search' ||
              requestName == 'web_fetch';
      if (isProviderNativeTool) {
        continue;
      }

      final originalName =
          _toolNameMapping?.originalFunctionNameForRequestName(requestName) ??
              requestName;
      toolCalls.add(ToolCall(
        id: block['id'] as String,
        callType: 'function',
        function: FunctionCall(
          name: originalName,
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

    // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>.
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

    // Note: Anthropic also provides cache_creation_input_tokens and cache_read_input_tokens.
    // These could be exposed in a future version of UsageInfo.

    return UsageInfo(
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: inputTokens + outputTokens,
      // Anthropic doesn't provide separate thinking_tokens in usage.
      // Thinking content is handled separately through content blocks.
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
      parts.add(calls.map((c) => c.toString()).join('\n'));
    }

    if (textContent != null) {
      parts.add(textContent);
    }

    return parts.join('\n');
  }

  @override
  ChatMessage get assistantMessage {
    final rawContent = _rawResponse['content'];

    final List<Map<String, dynamic>> blocks;
    if (rawContent is List) {
      blocks = rawContent
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } else {
      blocks = const [];
    }

    if (blocks.isEmpty) {
      return ChatMessage.assistant(text ?? '');
    }

    // For Anthropic-style providers, preserving the full `content` blocks is
    // required for multi-step tool use to maintain continuity (e.g. thinking
    // chains with signatures).
    return ChatMessage(
      role: ChatRole.assistant,
      messageType: const TextMessage(),
      content: '',
      protocolPayloads: {
        'anthropic': {
          'contentBlocks': blocks,
        },
      },
    );
  }
}
