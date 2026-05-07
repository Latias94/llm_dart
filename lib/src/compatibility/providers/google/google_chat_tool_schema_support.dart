part of 'google_chat_message_codec.dart';

final class _GoogleChatToolSchemaSupport {
  final GoogleClient client;

  _GoogleChatToolSchemaSupport({
    required this.client,
  });

  Map<String, dynamic> convertTool(Tool tool) {
    try {
      final schema = tool.function.parameters.toJson();

      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'No description provided',
        'parameters': schema,
      };
    } catch (e) {
      client.logger.warning('Failed to convert tool ${tool.function.name}: $e');
      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'Tool with invalid schema',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      };
    }
  }
}
