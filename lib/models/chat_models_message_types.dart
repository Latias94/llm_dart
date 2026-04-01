part of 'chat_models.dart';

/// The type of a message in a chat conversation.
sealed class MessageType {
  const MessageType();
}

/// A text message
class TextMessage extends MessageType {
  const TextMessage();
}

/// An image message
class ImageMessage extends MessageType {
  final ImageMime mime;
  final List<int> data;

  const ImageMessage(this.mime, this.data);
}

/// File message for documents, audio, video, etc.
class FileMessage extends MessageType {
  final FileMime mime;
  final List<int> data;

  const FileMessage(this.mime, this.data);
}

/// An image URL message
class ImageUrlMessage extends MessageType {
  final String url;

  const ImageUrlMessage(this.url);
}

/// A tool use message
class ToolUseMessage extends MessageType {
  final List<ToolCall> toolCalls;

  const ToolUseMessage(this.toolCalls);
}

/// Tool result message
class ToolResultMessage extends MessageType {
  final List<ToolCall> results;

  const ToolResultMessage(this.results);
}
