part of 'google_chat_message_codec.dart';

final class _GoogleChatToolChoiceSupport {
  final GoogleClient client;

  _GoogleChatToolChoiceSupport({
    required this.client,
  });

  Map<String, dynamic> convertToolChoice(
    ToolChoice toolChoice,
    List<Tool> tools,
  ) {
    switch (toolChoice) {
      case AutoToolChoice():
        return {
          'function_calling_config': {
            'mode': 'AUTO',
          },
        };
      case AnyToolChoice():
        return {
          'function_calling_config': {
            'mode': 'ANY',
          },
        };
      case SpecificToolChoice(toolName: final toolName):
        final toolExists = tools.any((tool) => tool.function.name == toolName);
        if (!toolExists) {
          client.logger.warning(
            'Tool "$toolName" specified in SpecificToolChoice not found in '
            'available tools',
          );
          return {
            'function_calling_config': {
              'mode': 'AUTO',
            },
          };
        }
        return {
          'function_calling_config': {
            'mode': 'ANY',
            'allowed_function_names': [toolName],
          },
        };
      case NoneToolChoice():
        return {
          'function_calling_config': {
            'mode': 'NONE',
          },
        };
    }
  }
}
