import '../../models/content_block.dart';

/// OpenAI-specific text content block
class OpenAITextBlock implements ContentBlock {
  final String text;

  const OpenAITextBlock(this.text);

  @override
  String get displayText => text;

  @override
  String get providerId => 'openai';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': text,
      };
}

/// OpenAI image content block
class OpenAIImageBlock implements ContentBlock {
  final String imageUrl;
  final String? detail;

  const OpenAIImageBlock(this.imageUrl, {this.detail});

  @override
  String get displayText => '[Image]';

  @override
  String get providerId => 'openai';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image_url',
        'image_url': {
          'url': imageUrl,
          if (detail != null) 'detail': detail,
        },
      };
}

/// OpenAI-specific message builder for images and structured content
class OpenAIMessageBuilder {
  final void Function(ContentBlock) _addBlock;

  OpenAIMessageBuilder._(this._addBlock);

  /// Create an OpenAI message builder
  factory OpenAIMessageBuilder(void Function(ContentBlock) addBlock) => 
      OpenAIMessageBuilder._(addBlock);

  /// Add image content with optional detail level
  OpenAIMessageBuilder image(String imageUrl, {String? detail}) {
    _addBlock(OpenAIImageBlock(imageUrl, detail: detail));
    return this;
  }

  /// Add text with an image (convenience method)
  OpenAIMessageBuilder textWithImage(String text, String imageUrl,
      {String? detail}) {
    _addBlock(OpenAITextBlock(text));
    _addBlock(OpenAIImageBlock(imageUrl, detail: detail));
    return this;
  }
}