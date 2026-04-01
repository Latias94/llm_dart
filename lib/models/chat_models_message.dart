part of 'chat_models.dart';

/// A single message in a chat conversation.
class ChatMessage {
  /// The role of who sent this message (user or assistant)
  final ChatRole role;

  /// The type of the message (text, image, audio, video, etc)
  final MessageType messageType;

  /// The text content of the message
  final String content;

  /// Optional name for the participant (useful for system messages)
  final String? name;

  /// Provider-specific extensions
  final Map<String, dynamic> extensions;

  const ChatMessage({
    required this.role,
    required this.messageType,
    required this.content,
    this.name,
    this.extensions = const {},
  });

  // Extension helpers
  T? getExtension<T>(String key) => extensions[key] as T?;
  bool hasExtension(String key) => extensions.containsKey(key);

  ChatMessage withExtension(String key, dynamic value) => ChatMessage(
        role: role,
        messageType: messageType,
        content: content,
        name: name,
        extensions: {...extensions, key: value},
      );

  /// Create a user message
  factory ChatMessage.user(String content) => ChatMessage(
        role: ChatRole.user,
        messageType: const TextMessage(),
        content: content,
      );

  /// Create an assistant message
  factory ChatMessage.assistant(String content) => ChatMessage(
        role: ChatRole.assistant,
        messageType: const TextMessage(),
        content: content,
      );

  /// Create a system message
  factory ChatMessage.system(
    String content, {
    String? name,
  }) =>
      ChatMessage(
        role: ChatRole.system,
        messageType: const TextMessage(),
        content: content,
        name: name,
      );

  /// Create an image message
  factory ChatMessage.image({
    required ChatRole role,
    required ImageMime mime,
    required List<int> data,
    String content = '',
  }) =>
      ChatMessage(
        role: role,
        messageType: ImageMessage(mime, data),
        content: content,
      );

  /// Create an image URL message
  factory ChatMessage.imageUrl({
    required ChatRole role,
    required String url,
    String content = '',
  }) =>
      ChatMessage(
        role: role,
        messageType: ImageUrlMessage(url),
        content: content,
      );

  /// Create a file message
  factory ChatMessage.file({
    required ChatRole role,
    required FileMime mime,
    required List<int> data,
    String content = '',
  }) =>
      ChatMessage(
        role: role,
        messageType: FileMessage(mime, data),
        content: content,
      );

  /// Create a PDF document message (convenience method)
  factory ChatMessage.pdf({
    required ChatRole role,
    required List<int> data,
    String content = '',
  }) =>
      ChatMessage.file(
        role: role,
        mime: FileMime.pdf,
        data: data,
        content: content,
      );

  /// Create a tool use message
  factory ChatMessage.toolUse({
    required List<ToolCall> toolCalls,
    String content = '',
  }) =>
      ChatMessage(
        role: ChatRole.assistant,
        messageType: ToolUseMessage(toolCalls),
        content: content,
      );

  /// Create a tool result message
  factory ChatMessage.toolResult({
    required List<ToolCall> results,
    String content = '',
  }) =>
      ChatMessage(
        role: ChatRole.user,
        messageType: ToolResultMessage(results),
        content: content,
      );
}
