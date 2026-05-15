part of 'anthropic_messages_codec.dart';

Map<String, Object?> _encodeAnthropicAssistantToolCallPart(
  ToolCallPromptPart part,
) {
  final input = normalizeJsonValue(
        part.input,
        path: 'assistant.toolCall(${part.toolCallId}).input',
      ) ??
      const <String, Object?>{};

  if (part.providerExecuted) {
    if (part.toolName.startsWith('mcp.')) {
      final serverName = part.title?.trim();
      if (serverName == null || serverName.isEmpty) {
        throw UnsupportedError(
          'Anthropic MCP tool replay requires a non-empty server title.',
        );
      }

      return {
        'type': 'mcp_tool_use',
        'id': part.toolCallId,
        'name': part.toolName.substring(4),
        'server_name': serverName,
        'input': input,
      };
    }

    return {
      'type': 'server_tool_use',
      'id': part.toolCallId,
      'name': part.toolName,
      'input': input,
    };
  }

  return {
    'type': 'tool_use',
    'id': part.toolCallId,
    'name': part.toolName,
    'input': input,
  };
}

Iterable<Map<String, Object?>> _encodeAnthropicToolReplayParts(
  PromptPart part,
) sync* {
  if (part is ToolResultPromptPart) {
    if (part.toolName.startsWith('mcp.')) {
      yield {
        'type': 'mcp_tool_result',
        'tool_use_id': part.toolCallId,
        'content': normalizeJsonValue(
              part.toolOutput.value,
              path: 'toolResult(${part.toolCallId}).output',
            ) ??
            const <String, Object?>{},
        if (part.isError) 'is_error': true,
      };
      return;
    }

    yield {
      'type': 'tool_result',
      'tool_use_id': part.toolCallId,
      'content': _encodeAnthropicToolOutput(
        part.toolOutput,
        path: 'toolResult(${part.toolCallId}).output',
      ),
      if (part.isError) 'is_error': true,
    };
    return;
  }

  if (part is CustomPromptPart) {
    final customToolResult = _encodeAnthropicCustomToolResultPart(part);
    if (customToolResult != null) {
      yield customToolResult;
      return;
    }
  }

  if (part is ToolApprovalResponsePromptPart) {
    return;
  }

  throw UnsupportedError(
    'Anthropic tool prompt part ${part.runtimeType} is not supported yet.',
  );
}

Map<String, Object?>? _encodeAnthropicCustomToolResultPart(
  CustomPromptPart part,
) {
  switch (part.kind) {
    case 'anthropic.result.web_fetch':
      final payload = _anthropicJsonObject(
        part.data,
        path: 'tool.custom(${part.kind})',
      );
      if (payload['replayRole'] != 'tool') {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires replayRole="tool".',
        );
      }

      final block = _anthropicJsonObject(
        payload['block'],
        path: 'tool.custom(${part.kind}).block',
      );
      final blockType = block['type'];
      if (blockType != 'web_fetch_tool_result') {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires a web_fetch_tool_result block.',
        );
      }

      final toolUseId = block['tool_use_id'];
      if (toolUseId is! String || toolUseId.isEmpty) {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires a non-empty tool_use_id.',
        );
      }

      return block;
    case 'anthropic.result.web_search':
      final payload = _anthropicJsonObject(
        part.data,
        path: 'tool.custom(${part.kind})',
      );
      if (payload['replayRole'] != 'tool') {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires replayRole="tool".',
        );
      }

      final block = _anthropicJsonObject(
        payload['block'],
        path: 'tool.custom(${part.kind}).block',
      );
      final blockType = block['type'];
      if (blockType != 'web_search_tool_result') {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires a web_search_tool_result block.',
        );
      }

      final toolUseId = block['tool_use_id'];
      if (toolUseId is! String || toolUseId.isEmpty) {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires a non-empty tool_use_id.',
        );
      }

      return block;
    case 'anthropic.result.tool_search':
      final payload = _anthropicJsonObject(
        part.data,
        path: 'tool.custom(${part.kind})',
      );
      if (payload['replayRole'] != 'tool') {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires replayRole="tool".',
        );
      }

      final block = _anthropicJsonObject(
        payload['block'],
        path: 'tool.custom(${part.kind}).block',
      );
      final blockType = block['type'];
      if (blockType != 'tool_search_tool_result') {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires a tool_search_tool_result block.',
        );
      }

      final toolUseId = block['tool_use_id'];
      if (toolUseId is! String || toolUseId.isEmpty) {
        throw UnsupportedError(
          'Anthropic custom tool replay "${part.kind}" requires a non-empty tool_use_id.',
        );
      }

      _anthropicJsonObject(
        block['content'],
        path: 'tool.custom(${part.kind}).block.content',
      );

      return block;
    case 'anthropic.result.code_execution':
      try {
        final replay = AnthropicCodeExecutionReplay.parseData(
          part.data,
          providerMetadata: mergeProviderReplayMetadata(
            providerOptions: part.providerOptions,
          ),
        );
        return replay.block;
      } on FormatException catch (error) {
        throw UnsupportedError(error.message);
      }
    default:
      return null;
  }
}
