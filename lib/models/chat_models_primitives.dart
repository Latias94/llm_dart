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
