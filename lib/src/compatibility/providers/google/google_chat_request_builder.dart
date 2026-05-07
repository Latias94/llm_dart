import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
import 'google_chat_message_codec.dart';

part 'google_chat_request_config_support.dart';
part 'google_chat_request_content_support.dart';

/// Request-shaping support for the Google compatibility chat shell.
class GoogleChatRequestBuilder {
  final GoogleClient client;
  final GoogleConfig config;
  late final _GoogleChatRequestConfigSupport _configSupport;
  late final _GoogleChatRequestContentSupport _contentSupport;

  GoogleChatRequestBuilder({
    required this.client,
    required this.config,
  }) {
    final messageCodec = GoogleChatMessageCodec(
      client: client,
      config: config,
    );
    _configSupport = _GoogleChatRequestConfigSupport(
      config: config,
      messageCodec: messageCodec,
    );
    _contentSupport = _GoogleChatRequestContentSupport(
      config: config,
      messageCodec: messageCodec,
    );
  }

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final contents = _contentSupport.buildContents(messages);
    return _configSupport.buildBodyWithConfig(
      contents,
      tools,
      stream: stream,
    );
  }
}
