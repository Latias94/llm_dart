part of 'anthropic_compat_support.dart';

final class _AnthropicCompatToolResultConverter {
  const _AnthropicCompatToolResultConverter();

  core.ToolPromptMessage convertToolResultMessage(
    AnthropicLegacyToolResultBlock block, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    final descriptor = toolDescriptors[block.toolCallId];
    final toolName = descriptor?.toolName ?? _fallbackToolResultName(block);

    if (block.customKind != null && block.rawBlock != null) {
      return core.ToolPromptMessage(
        toolName: toolName,
        parts: [
          core.CustomPromptPart(
            kind: block.customKind!,
            data: {
              'replayRole': 'tool',
              'toolCallId': block.toolCallId,
              'toolName': toolName,
              'block': block.rawBlock,
            },
          ),
        ],
      );
    }

    return core.ToolPromptMessage(
      toolName: toolName,
      parts: [
        core.ToolResultPromptPart(
          toolCallId: block.toolCallId,
          toolName: toolName,
          output: block.output,
          isError: block.isError,
        ),
      ],
    );
  }

  String _fallbackToolResultName(AnthropicLegacyToolResultBlock block) {
    return switch (block.blockType) {
      'mcp_tool_result' => 'mcp.unknown',
      'web_search_tool_result' => 'web_search',
      'web_fetch_tool_result' => 'web_fetch',
      'tool_search_tool_result' => 'tool_search',
      _ => 'tool',
    };
  }
}

final class _AnthropicCompatToolDescriptor {
  final String toolName;

  const _AnthropicCompatToolDescriptor({
    required this.toolName,
  });
}
