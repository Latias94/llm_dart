part of 'request_builder.dart';

final class _AnthropicToolExtractionSupport {
  const _AnthropicToolExtractionSupport();

  ToolExtractionResult extractFromMessage(ChatMessage message) {
    final tools = <Tool>[];
    Map<String, dynamic>? cacheControl;

    final anthropicData = message.getExtension<Map<String, dynamic>>(
      'anthropic',
    );
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map<String, dynamic>) {
            if (block['cache_control'] != null && block['text'] == '') {
              cacheControl = block['cache_control'];
            } else if (block['type'] == 'tools') {
              tools.addAll(convertToolsFromBlock(block));
            }
          }
        }
      }
    }

    return ToolExtractionResult(tools: tools, cacheControl: cacheControl);
  }

  List<Tool> convertToolsFromBlock(Map<String, dynamic> toolsBlock) {
    final tools = <Tool>[];
    final toolsList = toolsBlock['tools'] as List<dynamic>?;

    if (toolsList != null) {
      for (final toolData in toolsList) {
        if (toolData is Map<String, dynamic>) {
          if (toolData.containsKey('function') &&
              toolData.containsKey('type')) {
            final function = toolData['function'] as Map<String, dynamic>;
            tools.add(
              Tool(
                toolType: toolData['type'] as String? ?? 'function',
                function: FunctionTool(
                  name: function['name'] as String,
                  description: function['description'] as String,
                  parameters: ParametersSchema.fromJson(
                    function['parameters'] as Map<String, dynamic>,
                  ),
                ),
              ),
            );
          } else {
            try {
              tools.add(Tool.fromJson(toolData));
            } catch (e) {
              continue;
            }
          }
        }
      }
    }

    return tools;
  }
}
