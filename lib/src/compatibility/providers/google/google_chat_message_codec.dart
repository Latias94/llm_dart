import 'dart:convert';

import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';

part 'google_chat_message_content_support.dart';
part 'google_chat_message_media_support.dart';
part 'google_chat_tool_choice_support.dart';
part 'google_chat_tool_message_support.dart';
part 'google_chat_tool_schema_support.dart';
part 'google_chat_tool_support.dart';

/// Provider-local codec for Google chat message and tool payloads.
final class GoogleChatMessageCodec {
  final GoogleClient client;
  final GoogleConfig config;
  late final _GoogleChatMessageContentSupport _contentSupport;
  late final _GoogleChatToolSupport _toolSupport;

  GoogleChatMessageCodec({
    required this.client,
    required this.config,
  }) {
    _contentSupport = _GoogleChatMessageContentSupport(
      client: client,
      config: config,
    );
    _toolSupport = _GoogleChatToolSupport(client: client);
  }

  Map<String, dynamic> convertMessage(ChatMessage message) {
    return _contentSupport.convertMessage(message);
  }

  Map<String, dynamic> convertTool(Tool tool) {
    return _toolSupport.convertTool(tool);
  }

  Map<String, dynamic> convertToolChoice(
    ToolChoice toolChoice,
    List<Tool> tools,
  ) {
    return _toolSupport.convertToolChoice(toolChoice, tools);
  }
}
