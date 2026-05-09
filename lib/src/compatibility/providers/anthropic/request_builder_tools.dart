import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/anthropic/config.dart';
import 'request_builder_models.dart';
import 'request_builder_tool_extraction_support.dart';
import 'request_builder_tool_schema_support.dart';
import 'request_builder_tool_web_search_support.dart';

ProcessedTools processAnthropicTools(
  AnthropicConfig config,
  List<ChatMessage> messages,
  List<Tool>? configTools,
) {
  final messageTools = <Tool>[];
  Map<String, dynamic>? toolCacheControl;

  for (final message in messages) {
    final result = extractAnthropicToolsFromMessage(message);
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

ToolExtractionResult extractAnthropicToolsFromMessage(ChatMessage message) {
  return const AnthropicToolExtractionSupport().extractFromMessage(message);
}

Map<String, dynamic> convertAnthropicTool(
  AnthropicConfig config,
  Tool tool,
) {
  try {
    if (tool.function.name == 'web_search') {
      return convertAnthropicWebSearchTool(config);
    }

    return const AnthropicToolSchemaSupport().convertFunctionTool(tool);
  } catch (e) {
    throw ArgumentError(
      'Failed to convert tool "${tool.function.name}" to Anthropic format: $e',
    );
  }
}
