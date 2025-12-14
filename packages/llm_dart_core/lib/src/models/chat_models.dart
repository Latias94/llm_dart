// Chat and prompt models.
//
// llm_dart_core is prompt-first: ModelMessage + ChatContentPart are the only
// supported conversation types for chat capabilities.

import 'dart:convert';
import 'tool_models.dart';

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

  /// Convert ImageMime to the generic FileMime used for file-based parts.
  FileMime toFileMime() {
    switch (this) {
      case ImageMime.jpeg:
        return FileMime.jpeg;
      case ImageMime.png:
        return FileMime.png;
      case ImageMime.gif:
        return FileMime.gif;
      case ImageMime.webp:
        return FileMime.webp;
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

/// ============================
/// New content-part abstractions
/// ============================

/// Base class for structured content parts inside a chat message.
///
/// This provides an internal, provider-agnostic representation that can
/// be mapped to different provider-specific schemas (e.g. OpenAI, Anthropic,
/// Google Gemini) without losing semantic information.
sealed class ChatContentPart {
  /// Provider-specific options for this part.
  ///
  /// Examples:
  /// - Anthropic: cache control or citation metadata
  /// - Google: thought signatures or media-specific options
  final Map<String, dynamic>? providerOptions;

  const ChatContentPart({this.providerOptions});
}

/// Text content produced by or sent to the model.
class TextContentPart extends ChatContentPart {
  final String text;

  const TextContentPart(this.text, {super.providerOptions});
}

/// Reasoning / chain-of-thought style content.
///
/// This is primarily intended for:
/// - Providers that support visible reasoning output (e.g. Anthropic, Gemini)
/// - Few-shot examples that demonstrate reasoning steps
class ReasoningContentPart extends ChatContentPart {
  final String text;

  const ReasoningContentPart(this.text, {super.providerOptions});
}

/// File or binary content (documents, images, audio, video, etc.).
class FileContentPart extends ChatContentPart {
  final FileMime mime;
  final List<int> data;
  final String? filename;
  final String? uri;

  const FileContentPart(
    this.mime,
    this.data, {
    this.filename,
    this.uri,
    super.providerOptions,
  });
}

/// URL-based file or media content (e.g., remote images or documents).
///
/// This mirrors the Vercel AI SDK's "file part" concept where the payload
/// is a URL and the [mime] communicates the intended media type.
class UrlFileContentPart extends ChatContentPart {
  final String url;
  final FileMime mime;
  final String? filename;

  const UrlFileContentPart(
    this.url, {
    this.mime = const FileMime('image/*'),
    this.filename,
    super.providerOptions,
  });
}

/// Payload type for tool results.
///
/// This mirrors the intent of Vercel AI's LanguageModelV3ToolResultOutput
/// while staying minimal for now. Additional variants can be added as
/// providers expose richer structured tool outputs.
sealed class ToolResultPayload {
  const ToolResultPayload();
}

/// Tool result represented as plain text.
class ToolResultTextPayload extends ToolResultPayload {
  final String value;

  const ToolResultTextPayload(this.value);
}

/// Tool result represented as JSON.
class ToolResultJsonPayload extends ToolResultPayload {
  final Map<String, dynamic> value;

  const ToolResultJsonPayload(this.value);
}

/// Tool result represented as a list of structured content parts.
///
/// This is a future-proof container for multi-modal tool outputs.
class ToolResultContentPayload extends ToolResultPayload {
  final List<ChatContentPart> parts;

  const ToolResultContentPayload(this.parts);
}

/// Tool result represented as an error message.
class ToolResultErrorPayload extends ToolResultPayload {
  final String message;

  const ToolResultErrorPayload(this.message);
}

/// Tool call content part, usually generated by the model.
class ToolCallContentPart extends ChatContentPart {
  final String toolName;
  final String argumentsJson;
  final String? toolCallId;

  const ToolCallContentPart({
    required this.toolName,
    required this.argumentsJson,
    this.toolCallId,
    super.providerOptions,
  });
}

/// Tool result content part, corresponding to a previous tool call.
class ToolResultContentPart extends ChatContentPart {
  final String toolCallId;
  final String toolName;
  final ToolResultPayload payload;

  const ToolResultContentPart({
    required this.toolCallId,
    required this.toolName,
    required this.payload,
    super.providerOptions,
  });
}

/// High-level model message built from structured content parts.
///
/// This is the provider-agnostic, multi-part representation that providers
/// should consume internally for request/response mapping.
class ModelMessage {
  final ChatRole role;
  final List<ChatContentPart> parts;

  /// Provider-specific options for this message.
  ///
  /// Examples:
  /// - Anthropic: cache control defaults for all parts
  /// - Google: system-level modifiers or media options
  final Map<String, dynamic> providerOptions;

  const ModelMessage({
    required this.role,
    required this.parts,
    this.providerOptions = const {},
  });

  /// Convenience constructor for a user text message.
  ///
  /// This is equivalent to creating a [ModelMessage] with a single
  /// [TextContentPart] and [ChatRole.user].
  factory ModelMessage.userText(
    String text, {
    Map<String, dynamic> providerOptions = const {},
  }) {
    return ModelMessage(
      role: ChatRole.user,
      parts: <ChatContentPart>[TextContentPart(text)],
      providerOptions: providerOptions,
    );
  }

  /// Convenience constructor for a system text message.
  ///
  /// This is equivalent to creating a [ModelMessage] with a single
  /// [TextContentPart] and [ChatRole.system].
  factory ModelMessage.systemText(
    String text, {
    Map<String, dynamic> providerOptions = const {},
  }) {
    return ModelMessage(
      role: ChatRole.system,
      parts: <ChatContentPart>[TextContentPart(text)],
      providerOptions: providerOptions,
    );
  }

  /// Convenience constructor for an assistant text message.
  ///
  /// This is equivalent to creating a [ModelMessage] with a single
  /// [TextContentPart] and [ChatRole.assistant].
  factory ModelMessage.assistantText(
    String text, {
    Map<String, dynamic> providerOptions = const {},
  }) {
    return ModelMessage(
      role: ChatRole.assistant,
      parts: <ChatContentPart>[TextContentPart(text)],
      providerOptions: providerOptions,
    );
  }
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

/// Tools block for storing tools in messages
/// This allows tools to be cached and processed by providers
class ToolsBlock implements ContentBlock {
  final List<Tool> tools;

  ToolsBlock(this.tools);

  @override
  String get displayText => '[${tools.length} tools defined]';

  @override
  String get providerId => 'universal';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tools',
        'tools': tools.map((tool) => tool.toJson()).toList(),
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

  // Provider-specific options that should be attached to the resulting
  // ModelMessage.providerOptions. Each provider can supply its own options map.
  final Map<String, Map<String, dynamic>> _providerOptions = {};

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

  /// Add tools to this message
  ///
  /// This allows tools to be associated with specific messages,
  /// enabling provider-specific caching and processing.
  ///
  /// Example:
  /// ```dart
  /// MessageBuilder.system()
  ///     .tools([tool1, tool2, tool3])
  ///     .anthropicConfig((anthropic) => anthropic.cache())  // Cache the tools
  ///     .build();
  /// ```
  MessageBuilder tools(List<Tool> tools) {
    // Add a special block to store tools for provider processing
    addBlock(ToolsBlock(tools));
    return this;
  }

  // Method for providers to add blocks
  void addBlock(ContentBlock block) {
    _blocks.add(block);
  }

  /// Set provider-specific options for a given provider id.
  ///
  /// These options will be merged into [ModelMessage.providerOptions] for that
  /// provider. If options already exist, the new values will be merged on top.
  void setProviderOptions(String providerId, Map<String, dynamic> options) {
    final existing = _providerOptions[providerId] ?? <String, dynamic>{};
    _providerOptions[providerId] = {...existing, ...options};
  }

  /// Build a prompt-first [ModelMessage].
  ///
  /// Provider-specific content blocks are stored in [ModelMessage.providerOptions]
  /// so providers can interpret advanced features (e.g. Anthropic cache control)
  /// without relying on legacy shims.
  ModelMessage build() {
    // Convert blocks into structured prompt parts.
    final parts = <ChatContentPart>[];

    for (final block in _blocks) {
      if (block is ToolsBlock) continue;

      final json = block.toJson();
      final type = json['type'];
      if (type == 'tools') {
        // Tool definitions are handled out-of-band by provider request builders.
        continue;
      }

      // Provider-specific cache markers (e.g. Anthropic cache_control flags)
      // are metadata-only and should not surface as empty text parts.
      if (block.providerId != 'universal' &&
          type == 'text' &&
          json['cache_control'] != null) {
        final text = json['text'];
        if (text is String && text.isEmpty) {
          continue;
        }
      }

      parts.add(TextContentPart(block.displayText));
    }

    // Group blocks by provider for providerOptions.
    final providerOptions = <String, dynamic>{};

    final providerGroups = <String, List<ContentBlock>>{};
    final universalTools = <ToolsBlock>[];

    for (final block in _blocks) {
      if (block.providerId == 'universal') {
        if (block is ToolsBlock) {
          universalTools.add(block);
        }
        continue;
      }

      providerGroups.putIfAbsent(block.providerId, () => []).add(block);
    }

    // Preserve the previous behavior where tools can be cached together with
    // Anthropic cache markers by moving tool blocks into the Anthropic group
    // when a cache marker is present.
    if (providerGroups.containsKey('anthropic') && universalTools.isNotEmpty) {
      final anthropicBlocks = providerGroups['anthropic']!;

      final hasCacheMarker = anthropicBlocks.any((block) {
        final json = block.toJson();
        return json['cache_control'] != null && json['text'] == '';
      });

      if (hasCacheMarker) {
        for (final toolsBlock in universalTools) {
          anthropicBlocks.add(_AnthropicToolsBlockWrapper(toolsBlock.tools));
        }
      }
    }

    for (final entry in providerGroups.entries) {
      providerOptions[entry.key] = {
        'contentBlocks': entry.value.map((block) => block.toJson()).toList(),
      };
    }

    // Merge provider-specific options into providerOptions.
    for (final entry in _providerOptions.entries) {
      final providerId = entry.key;
      final options = entry.value;
      final existing =
          providerOptions[providerId] as Map<String, dynamic>? ?? {};
      providerOptions[providerId] = {...existing, ...options};
    }

    if (_name != null && _name!.isNotEmpty) {
      providerOptions['name'] = _name;
    }

    return ModelMessage(
      role: _role,
      parts: parts,
      providerOptions: providerOptions,
    );
  }
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

/// Internal wrapper to make ToolsBlock appear as anthropic-specific
class _AnthropicToolsBlockWrapper implements ContentBlock {
  final List<Tool> tools;

  _AnthropicToolsBlockWrapper(this.tools);

  @override
  String get displayText => '[${tools.length} tools defined]';

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tools',
        'tools': tools.map((tool) => tool.toJson()).toList(),
      };
}
