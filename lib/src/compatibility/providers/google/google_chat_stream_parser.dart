import '../../../../core/capability.dart';
import 'client.dart';
import 'google_chat_stream_support.dart';

/// Stateful streamed-event parser for the Google compatibility chat shell.
class GoogleChatStreamParser {
  final GoogleChatStreamSupport _support;

  GoogleChatStreamParser({
    required this.client,
  }) : _support = GoogleChatStreamSupport(client: client);

  final GoogleClient client;

  void reset() {
    _support.reset();
  }

  List<ChatStreamEvent> parseChunk(String chunk) {
    return _support.parseChunk(chunk);
  }
}
