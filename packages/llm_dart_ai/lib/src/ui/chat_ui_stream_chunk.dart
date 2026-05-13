import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';

sealed class ChatUiStreamChunk {
  const ChatUiStreamChunk();
}

final class ChatUiMessageStartChunk extends ChatUiStreamChunk {
  final String? messageId;
  final Map<String, Object?> metadata;

  ChatUiMessageStartChunk({
    this.messageId,
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(metadata);
}

final class ChatUiMessageMetadataChunk extends ChatUiStreamChunk {
  final Map<String, Object?> metadata;

  ChatUiMessageMetadataChunk({
    required Map<String, Object?> metadata,
  }) : metadata = Map.unmodifiable(metadata);
}

final class ChatUiEventChunk extends ChatUiStreamChunk {
  final TextStreamEvent event;

  const ChatUiEventChunk(this.event);
}

final class ChatUiDataPartChunk<T> extends ChatUiStreamChunk {
  final DataUiPart<T> part;

  const ChatUiDataPartChunk(this.part);
}

final class ChatUiTransientDataPartChunk<T> extends ChatUiStreamChunk {
  final DataUiPart<T> part;

  const ChatUiTransientDataPartChunk(this.part);
}

final class ChatUiMessageFinishChunk extends ChatUiStreamChunk {
  final Map<String, Object?> metadata;

  ChatUiMessageFinishChunk({
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(metadata);
}
