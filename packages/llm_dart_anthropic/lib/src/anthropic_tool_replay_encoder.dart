import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_custom_tool_replay_encoder.dart';
import 'anthropic_prompt_limitations.dart';
import 'anthropic_tool_result_replay_encoder.dart';

final class AnthropicToolReplayEncoder {
  final AnthropicCustomToolReplayEncoder customToolReplayEncoder;
  final AnthropicToolResultReplayEncoder toolResultReplayEncoder;

  const AnthropicToolReplayEncoder({
    this.customToolReplayEncoder = const AnthropicCustomToolReplayEncoder(),
    this.toolResultReplayEncoder = const AnthropicToolResultReplayEncoder(),
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
      yield toolResultReplayEncoder.encode(part);
      return;
    }

    if (part is CustomPromptPart) {
      final customToolResult = customToolReplayEncoder.encode(part);
      if (customToolResult != null) {
        yield customToolResult;
        return;
      }
    }

    if (part is ToolApprovalResponsePromptPart) {
      return;
    }

    throw unsupportedAnthropicPromptPart(role: 'tool', part: part);
  }
}
