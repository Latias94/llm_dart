import 'dart:convert';

/// Role of a participant in a chat conversation.
enum ChatRole {
  /// The user/human participant in the conversation
  user,

  /// The AI assistant participant in the conversation
  assistant,

  /// System message for setting context
  system,
}

/// The supported MIME type of an image.
enum ImageMime {
  /// JPEG image
  jpeg,

  /// PNG image
  png,

  /// GIF image
  gif,

  /// WebP image
  webp,
}

extension ImageMimeExtension on ImageMime {
  String get mimeType {
    switch (this) {
      case ImageMime.jpeg:
        return 'image/jpeg';
      case ImageMime.png:
        return 'image/png';
      case ImageMime.gif:
        return 'image/gif';
      case ImageMime.webp:
        return 'image/webp';
    }
  }
}

/// General MIME type for files
class FileMime {
  final String mimeType;

  const FileMime(this.mimeType);

  // Image types
  static const png = FileMime('image/png');
  static const jpeg = FileMime('image/jpeg');
  static const gif = FileMime('image/gif');
  static const webp = FileMime('image/webp');

  // Common document types
  static const pdf = FileMime('application/pdf');
  static const docx = FileMime(
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
  static const doc = FileMime('application/msword');
  static const xlsx = FileMime(
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  static const xls = FileMime('application/vnd.ms-excel');
  static const pptx = FileMime(
      'application/vnd.openxmlformats-officedocument.presentationml.presentation');
  static const ppt = FileMime('application/vnd.ms-powerpoint');
  static const txt = FileMime('text/plain');
  static const csv = FileMime('text/csv');
  static const json = FileMime('application/json');
  static const xml = FileMime('application/xml');

  // Audio types
  static const mp3 = FileMime('audio/mpeg');
  static const wav = FileMime('audio/wav');
  static const m4a = FileMime('audio/mp4');
  static const ogg = FileMime('audio/ogg');

  // Video types
  static const mp4 = FileMime('video/mp4');
  static const avi = FileMime('video/x-msvideo');
  static const mov = FileMime('video/quicktime');
  static const webm = FileMime('video/webm');

  // Archive types
  static const zip = FileMime('application/zip');
  static const rar = FileMime('application/vnd.rar');
  static const tar = FileMime('application/x-tar');
  static const gz = FileMime('application/gzip');

  /// Check if this is a document type
  bool get isDocument {
    return mimeType.startsWith('application/') &&
        (mimeType.contains('pdf') ||
            mimeType.contains('word') ||
            mimeType.contains('excel') ||
            mimeType.contains('powerpoint') ||
            mimeType.contains('text'));
  }

  /// Check if this is an audio type
  bool get isAudio => mimeType.startsWith('audio/');

  /// Check if this is a video type
  bool get isVideo => mimeType.startsWith('video/');

  /// Check if this is an archive type
  bool get isArchive {
    return mimeType == 'application/zip' ||
        mimeType == 'application/vnd.rar' ||
        mimeType == 'application/x-tar' ||
        mimeType == 'application/gzip';
  }

  /// Get a human-readable description of the file type
  String get description {
    switch (mimeType) {
      case 'application/pdf':
        return 'PDF Document';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'Word Document';
      case 'application/msword':
        return 'Word Document (Legacy)';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return 'Excel Spreadsheet';
      case 'application/vnd.ms-excel':
        return 'Excel Spreadsheet (Legacy)';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return 'PowerPoint Presentation';
      case 'application/vnd.ms-powerpoint':
        return 'PowerPoint Presentation (Legacy)';
      case 'text/plain':
        return 'Text File';
      case 'text/csv':
        return 'CSV File';
      case 'application/json':
        return 'JSON File';
      case 'audio/mpeg':
        return 'MP3 Audio';
      case 'audio/wav':
        return 'WAV Audio';
      case 'video/mp4':
        return 'MP4 Video';
      case 'application/zip':
        return 'ZIP Archive';
      default:
        return 'File ($mimeType)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileMime && other.mimeType == mimeType;
  }

  @override
  int get hashCode => mimeType.hashCode;

  @override
  String toString() => mimeType;
}

/// Represents an AI model with its metadata
class AIModel {
  /// The unique identifier of the model
  final String id;

  /// Human-readable description of the model
  final String? description;

  /// The object type (typically "model")
  final String object;

  /// The organization that owns the model
  final String? ownedBy;

  const AIModel({
    required this.id,
    this.description,
    this.object = 'model',
    this.ownedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (description != null) 'description': description,
        'object': object,
        if (ownedBy != null) 'owned_by': ownedBy,
      };

  factory AIModel.fromJson(Map<String, dynamic> json) => AIModel(
        id: json['id'] as String,
        description: json['description'] as String?,
        object: json['object'] as String? ?? 'model',
        ownedBy: json['owned_by'] as String?,
      );

  @override
  String toString() =>
      'AIModel(id: $id, description: $description, ownedBy: $ownedBy)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Tool call represents a function call that an LLM wants to make.
class ToolCall {
  /// The ID of the tool call.
  final String id;

  /// The type of the tool call (usually "function").
  final String callType;

  /// The function to call.
  final FunctionCall function;

  const ToolCall({
    required this.id,
    required this.callType,
    required this.function,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': callType,
        'function': function.toJson(),
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String,
        callType: json['type'] as String,
        function:
            FunctionCall.fromJson(json['function'] as Map<String, dynamic>),
      );

  @override
  String toString() => jsonEncode(toJson());
}

/// FunctionCall contains details about which function to call and with what arguments.
class FunctionCall {
  /// The name of the function to call.
  final String name;

  /// The arguments to pass to the function, typically serialized as a JSON string.
  final String arguments;

  const FunctionCall({required this.name, required this.arguments});

  Map<String, dynamic> toJson() => {'name': name, 'arguments': arguments};

  factory FunctionCall.fromJson(Map<String, dynamic> json) => FunctionCall(
        name: json['name'] as String,
        arguments: json['arguments'] as String,
      );

  @override
  String toString() => jsonEncode(toJson());
}

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

/// Simple interface for provider-specific blocks
abstract class ContentBlock {
  String get displayText;
  String get providerId;
  Map<String, dynamic> toJson();
}

/// Universal text block that works with all providers
class UniversalTextBlock implements ContentBlock {
  final String text;

  UniversalTextBlock(this.text);

  @override
  String get displayText => text;

  @override
  String get providerId => 'universal';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': text,
      };
}

/// Message builder for creating messages with provider-specific extensions
///
/// **Provider-Specific Content:**
/// Providers can add specialized content blocks through their extensions.
/// These blocks are stored alongside universal text blocks and processed
/// by each provider according to their specific requirements.
///
/// **API Conversion:**
/// - Universal content blocks are processed by all providers
/// - Provider-specific content blocks are processed only by their respective providers
/// - Each provider's _buildRequestBody handles mixed content appropriately
///
class MessageBuilder {
  final ChatRole _role;
  final List<ContentBlock> _blocks = [];
  String? _name;

  MessageBuilder._(this._role);

  // Factory methods
  static MessageBuilder system() => MessageBuilder._(ChatRole.system);
  static MessageBuilder user() => MessageBuilder._(ChatRole.user);
  static MessageBuilder assistant() => MessageBuilder._(ChatRole.assistant);

  // Universal methods
  MessageBuilder text(String text) {
    _blocks.add(UniversalTextBlock(text));
    return this;
  }

  MessageBuilder name(String name) {
    _name = name;
    return this;
  }

  // Method for providers to add blocks
  void addBlock(ContentBlock block) {
    _blocks.add(block);
  }

  // Build ChatMessage with extensions
  ChatMessage build() {
    // Create universal text content
    final content = _blocks.map((block) => block.displayText).join('\n');

    // Group blocks by provider
    final extensions = <String, dynamic>{};

    final providerGroups = <String, List<ContentBlock>>{};
    for (final block in _blocks) {
      if (block.providerId == 'universal') continue;

      providerGroups.putIfAbsent(block.providerId, () => []).add(block);
    }

    // Create extensions for each provider
    for (final entry in providerGroups.entries) {
      extensions[entry.key] = {
        'contentBlocks': entry.value.map((block) => block.toJson()).toList(),
      };
    }

    return ChatMessage(
      role: _role,
      messageType: const TextMessage(),
      content: content,
      name: _name,
      extensions: extensions,
    );
  }
}

/// Reasoning effort levels for models that support reasoning
enum ReasoningEffort {
  low,
  medium,
  high;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ReasoningEffort.low:
        return 'low';
      case ReasoningEffort.medium:
        return 'medium';
      case ReasoningEffort.high:
        return 'high';
    }
  }

  /// Create from string value
  static ReasoningEffort? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'low':
        return ReasoningEffort.low;
      case 'medium':
        return ReasoningEffort.medium;
      case 'high':
        return ReasoningEffort.high;
      default:
        return null;
    }
  }
}

/// Service tier levels for API requests
enum ServiceTier {
  auto,
  standard,
  priority;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ServiceTier.auto:
        return 'auto';
      case ServiceTier.standard:
        return 'standard_only';
      case ServiceTier.priority:
        return 'priority';
    }
  }

  /// Create from string value
  static ServiceTier? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'auto':
        return ServiceTier.auto;
      case 'standard':
      case 'standard_only':
        return ServiceTier.standard;
      case 'priority':
        return ServiceTier.priority;
      default:
        return null;
    }
  }
}

/// Request metadata for tracking and analytics
class RequestMetadata {
  /// External identifier for the user associated with the request
  final String? userId;

  /// Additional custom metadata
  final Map<String, dynamic>? customData;

  const RequestMetadata({
    this.userId,
    this.customData,
  });

  Map<String, dynamic> toJson() => {
        if (userId != null) 'user_id': userId,
        if (customData != null) ...customData!,
      };

  factory RequestMetadata.fromJson(Map<String, dynamic> json) =>
      RequestMetadata(
        userId: json['user_id'] as String?,
        customData: Map<String, dynamic>.from(json)
          ..remove('user_id'), // Remove user_id from custom data
      );

  @override
  String toString() =>
      'RequestMetadata(userId: $userId, customData: $customData)';
}
