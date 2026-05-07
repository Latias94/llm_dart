part of 'request_builder.dart';

ProcessedTools _processAnthropicTools(
  AnthropicConfig config,
  List<ChatMessage> messages,
  List<Tool>? configTools,
) {
  final messageTools = <Tool>[];
  Map<String, dynamic>? toolCacheControl;

  for (final message in messages) {
    final result = _extractAnthropicToolsFromMessage(message);
    messageTools.addAll(result.tools);
    toolCacheControl ??= result.cacheControl;
  }

  final allTools = <Tool>[];
  allTools.addAll(messageTools);

  final effectiveTools = configTools ?? config.tools;
  if (effectiveTools != null) {
    allTools.addAll(effectiveTools);
  }

  return ProcessedTools(
    tools: allTools,
    cacheControl: toolCacheControl,
  );
}

ToolExtractionResult _extractAnthropicToolsFromMessage(ChatMessage message) {
  return const _AnthropicToolExtractionSupport().extractFromMessage(message);
}

Map<String, dynamic> _convertAnthropicTool(
  AnthropicConfig config,
  Tool tool,
) {
  try {
    if (tool.function.name == 'web_search') {
      return _convertAnthropicWebSearchTool(config);
    }

    return const _AnthropicToolSchemaSupport().convertFunctionTool(tool);
  } catch (e) {
    throw ArgumentError(
      'Failed to convert tool "${tool.function.name}" to Anthropic format: $e',
    );
  }
}
