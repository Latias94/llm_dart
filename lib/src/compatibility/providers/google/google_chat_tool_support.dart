part of 'google_chat_message_codec.dart';

final class _GoogleChatToolSupport {
  final GoogleClient client;
  late final _GoogleChatToolChoiceSupport _choiceSupport;
  late final _GoogleChatToolMessageSupport _messageSupport;
  late final _GoogleChatToolSchemaSupport _schemaSupport;

  _GoogleChatToolSupport({
    required this.client,
  }) {
    _choiceSupport = _GoogleChatToolChoiceSupport(client: client);
    _messageSupport = _GoogleChatToolMessageSupport(client: client);
    _schemaSupport = _GoogleChatToolSchemaSupport(client: client);
  }

  Map<String, dynamic> convertTool(Tool tool) {
    return _schemaSupport.convertTool(tool);
  }

  Map<String, dynamic> convertToolChoice(
    ToolChoice toolChoice,
    List<Tool> tools,
  ) {
    return _choiceSupport.convertToolChoice(toolChoice, tools);
  }

  List<Map<String, dynamic>> convertToolUse(List<ToolCall> toolCalls) {
    return _messageSupport.convertToolUse(toolCalls);
  }

  List<Map<String, dynamic>> convertToolResult(List<ToolCall> results) {
    return _messageSupport.convertToolResult(results);
  }
}
