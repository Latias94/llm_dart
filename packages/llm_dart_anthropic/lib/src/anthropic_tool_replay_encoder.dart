import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_code_execution_replay.dart';
import 'anthropic_content_encoder.dart';
import 'anthropic_request_json.dart';

final class AnthropicToolReplayEncoder {
  final AnthropicContentEncoder contentEncoder;

  const AnthropicToolReplayEncoder({
    this.contentEncoder = const AnthropicContentEncoder(),
  });

  Map<String, Object?> encodeAssistantToolCallPart(
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

  Iterable<Map<String, Object?>> encodeToolReplayParts(
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
        'content': contentEncoder.encodeToolOutput(
          part.toolOutput,
          path: 'toolResult(${part.toolCallId}).output',
        ),
        if (part.isError) 'is_error': true,
      };
      return;
    }

    if (part is CustomPromptPart) {
      final customToolResult = _encodeCustomToolResultPart(part);
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

  Map<String, Object?>? _encodeCustomToolResultPart(
    CustomPromptPart part,
  ) {
    switch (part.kind) {
      case 'anthropic.result.web_fetch':
        final payload = normalizeAnthropicJsonObject(
          part.data,
          path: 'tool.custom(${part.kind})',
        );
        if (payload['replayRole'] != 'tool') {
          throw UnsupportedError(
            'Anthropic custom tool replay "${part.kind}" requires replayRole="tool".',
          );
        }

        final block = normalizeAnthropicJsonObject(
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
        final payload = normalizeAnthropicJsonObject(
          part.data,
          path: 'tool.custom(${part.kind})',
        );
        if (payload['replayRole'] != 'tool') {
          throw UnsupportedError(
            'Anthropic custom tool replay "${part.kind}" requires replayRole="tool".',
          );
        }

        final block = normalizeAnthropicJsonObject(
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
        final payload = normalizeAnthropicJsonObject(
          part.data,
          path: 'tool.custom(${part.kind})',
        );
        if (payload['replayRole'] != 'tool') {
          throw UnsupportedError(
            'Anthropic custom tool replay "${part.kind}" requires replayRole="tool".',
          );
        }

        final block = normalizeAnthropicJsonObject(
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

        normalizeAnthropicJsonObject(
          block['content'],
          path: 'tool.custom(${part.kind}).block.content',
        );

        return block;
      case 'anthropic.result.code_execution':
        try {
          final replay = AnthropicCodeExecutionReplay.parseData(
            part.data,
            providerMetadata: providerReplayMetadataFromOptions(
              part.providerOptions,
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
}
