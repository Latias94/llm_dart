import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import 'request_builder_message_extension_support.dart';
import 'request_builder_models.dart';

final class AnthropicToolExtractionSupport {
  const AnthropicToolExtractionSupport();

  static const _extensionSupport = AnthropicMessageExtensionSupport();

  ToolExtractionResult extractFromMessage(ChatMessage message) {
    final tools = <Tool>[];
    Map<String, dynamic>? cacheControl;

    for (final block in _extensionSupport.rawContentBlocksFor(message)) {
      if (_extensionSupport.isCacheMarker(block)) {
        cacheControl = block['cache_control'] as Map<String, dynamic>?;
      } else if (_extensionSupport.isToolsBlock(block)) {
        tools.addAll(convertToolsFromBlock(block));
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
