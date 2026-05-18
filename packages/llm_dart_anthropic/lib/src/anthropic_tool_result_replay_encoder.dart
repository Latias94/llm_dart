import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_content_encoder.dart';

final class AnthropicToolResultReplayEncoder {
  final AnthropicContentEncoder contentEncoder;

  const AnthropicToolResultReplayEncoder({
    this.contentEncoder = const AnthropicContentEncoder(),
  });

  Map<String, Object?> encode(ToolResultPromptPart part) {
    if (part.toolName.startsWith('mcp.')) {
      return _encodeMcpToolResult(part);
    }

    return {
      'type': 'tool_result',
      'tool_use_id': part.toolCallId,
      'content': contentEncoder.encodeToolOutput(
        part.toolOutput,
        path: 'toolResult(${part.toolCallId}).output',
      ),
      if (part.isError) 'is_error': true,
    };
  }

  Map<String, Object?> _encodeMcpToolResult(ToolResultPromptPart part) {
    return {
      'type': 'mcp_tool_result',
      'tool_use_id': part.toolCallId,
      'content': normalizeJsonValue(
            part.toolOutput.value,
            path: 'toolResult(${part.toolCallId}).output',
          ) ??
          const <String, Object?>{},
      if (part.isError) 'is_error': true,
    };
  }
}
