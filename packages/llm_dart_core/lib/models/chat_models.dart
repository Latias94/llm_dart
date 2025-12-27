import 'dart:convert';
import '../core/provider_options.dart';

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

  /// Provider-specific options for this tool call (namespaced).
  ///
  /// This is a best-effort escape hatch aligned with Vercel AI SDK's
  /// `providerOptions` propagation model.
  final ProviderOptions providerOptions;

  const ToolCall({
    required this.id,
    required this.callType,
    required this.function,
    this.providerOptions = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': callType,
        'function': function.toJson(),
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String,
        callType: json['type'] as String,
        function:
            FunctionCall.fromJson(json['function'] as Map<String, dynamic>),
        providerOptions: (json['providerOptions'] as Map?)
                ?.map<String, Map<String, dynamic>>((key, value) => MapEntry(
                      key.toString(),
                      (value as Map?)?.cast<String, dynamic>() ?? const {},
                    )) ??
            const {},
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

  /// Provider-specific protocol payloads (internal).
  ///
  /// This map is reserved for protocol adapters that need to carry
  /// provider-native content blocks or metadata through the legacy message
  /// model.
  ///
  /// Prefer these public surfaces instead:
  /// - `Prompt` IR (`llm_dart_ai`) for prompt composition (parts/messages).
  /// - `providerOptions` for provider-only knobs (escape hatch).
  @Deprecated(
    'ChatMessage.extensions is reserved for internal protocol adapters. '
    'Prefer Prompt IR (llm_dart_ai) and ChatMessage.providerOptions.',
  )
  final Map<String, dynamic> extensions;

  /// Provider-specific options for this message (namespaced).
  ///
  /// This is the preferred mechanism for provider-only knobs at the prompt
  /// layer, similar to Vercel AI SDK's `providerOptions`.
  final ProviderOptions providerOptions;

  const ChatMessage({
    required this.role,
    required this.messageType,
    required this.content,
    this.name,
    this.extensions = const {},
    this.providerOptions = const {},
  });

  // Extension helpers (internal/legacy).
  @Deprecated(
    'ChatMessage.extensions is reserved for internal protocol adapters. '
    'Prefer Prompt IR (llm_dart_ai) and ChatMessage.providerOptions.',
  )
  T? getExtension<T>(String key) => extensions[key] as T?;

  @Deprecated(
    'ChatMessage.extensions is reserved for internal protocol adapters. '
    'Prefer Prompt IR (llm_dart_ai) and ChatMessage.providerOptions.',
  )
  bool hasExtension(String key) => extensions.containsKey(key);

  @Deprecated(
    'ChatMessage.extensions is reserved for internal protocol adapters. '
    'Prefer Prompt IR (llm_dart_ai) and ChatMessage.providerOptions.',
  )
  ChatMessage withExtension(String key, dynamic value) => ChatMessage(
        role: role,
        messageType: messageType,
        content: content,
        name: name,
        extensions: {...extensions, key: value},
        providerOptions: providerOptions,
      );

  ChatMessage withProviderOptions(
      String providerId, Map<String, dynamic> value) {
    final updated = <String, Map<String, dynamic>>{
      ...providerOptions,
      providerId: {
        ...?providerOptions[providerId],
        ...value,
      },
    };
    return ChatMessage(
      role: role,
      messageType: messageType,
      content: content,
      name: name,
      // Protocol-internal: preserve legacy extensions when copying.
      // ignore: deprecated_member_use_from_same_package
      extensions: extensions,
      providerOptions: updated,
    );
  }

  /// Create a user message
  factory ChatMessage.user(
    String content, {
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: ChatRole.user,
        messageType: const TextMessage(),
        content: content,
        providerOptions: providerOptions,
      );

  /// Create an assistant message
  factory ChatMessage.assistant(
    String content, {
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: ChatRole.assistant,
        messageType: const TextMessage(),
        content: content,
        providerOptions: providerOptions,
      );

  /// Create a system message
  factory ChatMessage.system(
    String content, {
    String? name,
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: ChatRole.system,
        messageType: const TextMessage(),
        content: content,
        name: name,
        providerOptions: providerOptions,
      );

  /// Create an image message
  factory ChatMessage.image({
    required ChatRole role,
    required ImageMime mime,
    required List<int> data,
    String content = '',
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: role,
        messageType: ImageMessage(mime, data),
        content: content,
        providerOptions: providerOptions,
      );

  /// Create an image URL message
  factory ChatMessage.imageUrl({
    required ChatRole role,
    required String url,
    String content = '',
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: role,
        messageType: ImageUrlMessage(url),
        content: content,
        providerOptions: providerOptions,
      );

  /// Create a file message
  factory ChatMessage.file({
    required ChatRole role,
    required FileMime mime,
    required List<int> data,
    String content = '',
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: role,
        messageType: FileMessage(mime, data),
        content: content,
        providerOptions: providerOptions,
      );

  /// Create a PDF document message (convenience method)
  factory ChatMessage.pdf({
    required ChatRole role,
    required List<int> data,
    String content = '',
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage.file(
        role: role,
        mime: FileMime.pdf,
        data: data,
        content: content,
        providerOptions: providerOptions,
      );

  /// Create a tool use message
  factory ChatMessage.toolUse({
    required List<ToolCall> toolCalls,
    String content = '',
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: ChatRole.assistant,
        messageType: ToolUseMessage(toolCalls),
        content: content,
        providerOptions: providerOptions,
      );

  /// Create a tool result message
  factory ChatMessage.toolResult({
    required List<ToolCall> results,
    String content = '',
    ProviderOptions providerOptions = const {},
  }) =>
      ChatMessage(
        role: ChatRole.user,
        messageType: ToolResultMessage(results),
        content: content,
        providerOptions: providerOptions,
      );
}

/// Reasoning effort levels for models that support reasoning
enum ReasoningEffort {
  minimal,
  low,
  medium,
  high;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ReasoningEffort.minimal:
        return 'minimal';
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
      case 'minimal':
        return ReasoningEffort.minimal;
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

/// Verbosity levels for controlling output detail (GPT-5 feature)
enum Verbosity {
  low,
  medium,
  high;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case Verbosity.low:
        return 'low';
      case Verbosity.medium:
        return 'medium';
      case Verbosity.high:
        return 'high';
    }
  }

  /// Create from string value
  static Verbosity? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'low':
        return Verbosity.low;
      case 'medium':
        return Verbosity.medium;
      case 'high':
        return Verbosity.high;
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
