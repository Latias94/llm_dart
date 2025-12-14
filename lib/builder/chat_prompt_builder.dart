import 'package:llm_dart_core/llm_dart_core.dart';

/// Fluent builder for constructing ModelMessage instances with
/// multi-part, multi-modal content.
///
/// This is a convenience layer on top of the core chat content model
/// and is particularly useful for providers like Google (Gemini)
/// that support rich multi-modal inputs.
class ChatPromptBuilder {
  final ChatRole _role;
  final List<ChatContentPart> _parts = [];

  ChatPromptBuilder._(this._role);

  /// Create a user prompt builder.
  factory ChatPromptBuilder.user() => ChatPromptBuilder._(ChatRole.user);

  /// Create an assistant prompt builder.
  factory ChatPromptBuilder.assistant() =>
      ChatPromptBuilder._(ChatRole.assistant);

  /// Create a system prompt builder.
  factory ChatPromptBuilder.system() => ChatPromptBuilder._(ChatRole.system);

  /// Add a text part to the prompt.
  ChatPromptBuilder text(String text) {
    if (text.isNotEmpty) {
      _parts.add(TextContentPart(text));
    }
    return this;
  }

  /// Add an image from raw bytes.
  ///
  /// This is suitable for embedding small/medium images directly
  /// into the request. Large files should use provider-specific
  /// file APIs when available.
  ChatPromptBuilder imageBytes(
    List<int> bytes, {
    ImageMime mime = ImageMime.jpeg,
    String? filename,
  }) {
    _parts.add(
      FileContentPart(
        mime.toFileMime(),
        bytes,
        filename: filename,
      ),
    );
    return this;
  }

  /// Add a generic file from raw bytes.
  ChatPromptBuilder fileBytes(
    List<int> bytes, {
    required FileMime mime,
    String? filename,
  }) {
    _parts.add(
      FileContentPart(
        mime,
        bytes,
        filename: filename,
      ),
    );
    return this;
  }

  /// Add an image by URL.
  ///
  /// Providers that support URL-based files (such as Google Gemini
  /// via `fileData`) can map this to their native representation.
  ChatPromptBuilder imageUrl(
    String url, {
    FileMime mime = const FileMime('image/*'),
    String? filename,
  }) {
    _parts.add(
      UrlFileContentPart(
        url,
        mime: mime,
        filename: filename,
      ),
    );
    return this;
  }

  /// Add a generic file by URL.
  ///
  /// This mirrors the Vercel AI SDK file part semantics: callers provide
  /// the [mime] type and the remote URL. Provider support varies:
  /// - Some providers can reference URLs directly (e.g. Google via `fileUri`)
  /// - Others require uploading / inlining bytes
  ChatPromptBuilder fileUrl(
    String url, {
    required FileMime mime,
    String? filename,
  }) {
    _parts.add(
      UrlFileContentPart(
        url,
        mime: mime,
        filename: filename,
      ),
    );
    return this;
  }

  /// Add an audio file from raw bytes.
  ///
  /// This is a convenience helper over [fileBytes] for common audio
  /// formats such as MP3 or WAV.
  ChatPromptBuilder audioBytes(
    List<int> bytes, {
    FileMime mime = FileMime.mp3,
    String? filename,
  }) {
    return fileBytes(bytes, mime: mime, filename: filename);
  }

  /// Add an audio file by URL using a file-based part.
  ///
  /// Providers that support URL-based files can map this to their
  /// native representation (for example, Gemini using `fileData`).
  ChatPromptBuilder audioUrl(
    String url, {
    FileMime mime = FileMime.mp3,
    String? filename,
  }) {
    _parts.add(
      UrlFileContentPart(
        url,
        mime: mime,
        filename: filename,
      ),
    );
    return this;
  }

  /// Add a video file from raw bytes.
  ChatPromptBuilder videoBytes(
    List<int> bytes, {
    FileMime mime = FileMime.mp4,
    String? filename,
  }) {
    return fileBytes(bytes, mime: mime, filename: filename);
  }

  /// Add a video file by URL using a file-based part.
  ChatPromptBuilder videoUrl(
    String url, {
    FileMime mime = FileMime.mp4,
    String? filename,
  }) {
    _parts.add(
      UrlFileContentPart(
        url,
        mime: mime,
        filename: filename,
      ),
    );
    return this;
  }

  /// Build the ModelMessage instance.
  ModelMessage build({
    Map<String, dynamic> providerOptions = const {},
  }) {
    return ModelMessage(
      role: _role,
      parts: List<ChatContentPart>.unmodifiable(_parts),
      providerOptions: providerOptions,
    );
  }
}
