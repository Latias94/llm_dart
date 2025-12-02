/// Image generation related models for AI image generation functionality
library;

import '../core/capability.dart' show UsageInfo;

/// Image generation request configuration
class ImageGenerationRequest {
  /// Text prompt for image generation
  final String prompt;

  /// Model to use for generation
  final String? model;

  /// Negative prompt to avoid certain elements
  final String? negativePrompt;

  /// Image dimensions (e.g., '1024x1024', '512x512')
  final String? size;

  /// Number of images to generate
  final int? count;

  /// Random seed for reproducible results
  final int? seed;

  /// Number of inference steps (for compatible providers)
  final int? steps;

  /// Guidance scale for generation (for compatible providers)
  final double? guidanceScale;

  /// Whether to enhance the prompt (for compatible providers)
  final bool? enhancePrompt;

  /// Image style (for compatible providers)
  final String? style;

  /// Quality setting (for compatible providers)
  final String? quality;

  /// Response format (url or b64_json)
  final String? responseFormat;

  /// User identifier for monitoring and abuse detection
  final String? user;

  const ImageGenerationRequest({
    required this.prompt,
    this.model,
    this.negativePrompt,
    this.size,
    this.count,
    this.seed,
    this.steps,
    this.guidanceScale,
    this.enhancePrompt,
    this.style,
    this.quality,
    this.responseFormat,
    this.user,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        if (model != null) 'model': model,
        if (negativePrompt != null) 'negative_prompt': negativePrompt,
        if (size != null) 'size': size,
        if (count != null) 'count': count,
        if (seed != null) 'seed': seed,
        if (steps != null) 'steps': steps,
        if (guidanceScale != null) 'guidance_scale': guidanceScale,
        if (enhancePrompt != null) 'enhance_prompt': enhancePrompt,
        if (style != null) 'style': style,
        if (quality != null) 'quality': quality,
        if (responseFormat != null) 'response_format': responseFormat,
        if (user != null) 'user': user,
      };

  factory ImageGenerationRequest.fromJson(Map<String, dynamic> json) =>
      ImageGenerationRequest(
        prompt: json['prompt'] as String,
        model: json['model'] as String?,
        negativePrompt: json['negative_prompt'] as String?,
        size: json['size'] as String?,
        count: json['count'] as int?,
        seed: json['seed'] as int?,
        steps: json['steps'] as int?,
        guidanceScale: json['guidance_scale'] as double?,
        enhancePrompt: json['enhance_prompt'] as bool?,
        style: json['style'] as String?,
        quality: json['quality'] as String?,
        responseFormat: json['response_format'] as String?,
        user: json['user'] as String?,
      );
}

/// Image generation response with metadata
class ImageGenerationResponse {
  /// Generated image URLs or data
  final List<GeneratedImage> images;

  /// Model used for generation
  final String? model;

  /// Revised prompt (if prompt enhancement was used)
  final String? revisedPrompt;

  /// Usage information if available
  final UsageInfo? usage;

  const ImageGenerationResponse({
    required this.images,
    this.model,
    this.revisedPrompt,
    this.usage,
  });

  Map<String, dynamic> toJson() => {
        'images': images.map((img) => img.toJson()).toList(),
        if (model != null) 'model': model,
        if (revisedPrompt != null) 'revised_prompt': revisedPrompt,
        if (usage != null) 'usage': usage!.toJson(),
      };

  factory ImageGenerationResponse.fromJson(Map<String, dynamic> json) =>
      ImageGenerationResponse(
        images: (json['images'] as List)
            .map((img) => GeneratedImage.fromJson(img as Map<String, dynamic>))
            .toList(),
        model: json['model'] as String?,
        revisedPrompt: json['revised_prompt'] as String?,
        usage: json['usage'] != null
            ? UsageInfo.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
      );
}

/// Generated image information
class GeneratedImage {
  /// Image URL (for URL-based responses)
  final String? url;

  /// Image data as bytes (for direct data responses)
  final List<int>? data;

  /// Revised prompt for this specific image
  final String? revisedPrompt;

  /// Image format (png, jpeg, webp, etc.)
  final String? format;

  /// Image dimensions
  final ImageDimensions? dimensions;

  const GeneratedImage({
    this.url,
    this.data,
    this.revisedPrompt,
    this.format,
    this.dimensions,
  });

  Map<String, dynamic> toJson() => {
        if (url != null) 'url': url,
        if (data != null) 'data': data,
        if (revisedPrompt != null) 'revised_prompt': revisedPrompt,
        if (format != null) 'format': format,
        if (dimensions != null) 'dimensions': dimensions!.toJson(),
      };

  factory GeneratedImage.fromJson(Map<String, dynamic> json) => GeneratedImage(
        url: json['url'] as String?,
        data:
            json['data'] != null ? List<int>.from(json['data'] as List) : null,
        revisedPrompt: json['revised_prompt'] as String?,
        format: json['format'] as String?,
        dimensions: json['dimensions'] != null
            ? ImageDimensions.fromJson(
                json['dimensions'] as Map<String, dynamic>)
            : null,
      );
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  const ImageDimensions({required this.width, required this.height});

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
      };

  factory ImageDimensions.fromJson(Map<String, dynamic> json) =>
      ImageDimensions(
        width: json['width'] as int,
        height: json['height'] as int,
      );

  @override
  String toString() => '${width}x$height';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDimensions &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}

/// Image style options for generation
enum ImageStyle {
  /// Natural, photographic style
  natural,

  /// Vivid, artistic style
  vivid,

  /// Anime/cartoon style
  anime,

  /// Digital art style
  digitalArt,

  /// Oil painting style
  oilPainting,

  /// Watercolor style
  watercolor,

  /// Sketch/pencil style
  sketch,

  /// 3D render style
  render3d,

  /// Pixel art style
  pixelArt,

  /// Abstract style
  abstract;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ImageStyle.natural:
        return 'natural';
      case ImageStyle.vivid:
        return 'vivid';
      case ImageStyle.anime:
        return 'anime';
      case ImageStyle.digitalArt:
        return 'digital-art';
      case ImageStyle.oilPainting:
        return 'oil-painting';
      case ImageStyle.watercolor:
        return 'watercolor';
      case ImageStyle.sketch:
        return 'sketch';
      case ImageStyle.render3d:
        return '3d-render';
      case ImageStyle.pixelArt:
        return 'pixel-art';
      case ImageStyle.abstract:
        return 'abstract';
    }
  }

  /// Create from string value
  static ImageStyle? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'natural':
        return ImageStyle.natural;
      case 'vivid':
        return ImageStyle.vivid;
      case 'anime':
        return ImageStyle.anime;
      case 'digital-art':
        return ImageStyle.digitalArt;
      case 'oil-painting':
        return ImageStyle.oilPainting;
      case 'watercolor':
        return ImageStyle.watercolor;
      case 'sketch':
        return ImageStyle.sketch;
      case '3d-render':
        return ImageStyle.render3d;
      case 'pixel-art':
        return ImageStyle.pixelArt;
      case 'abstract':
        return ImageStyle.abstract;
      default:
        return null;
    }
  }
}

/// Image quality options
enum ImageQuality {
  /// Standard quality
  standard,

  /// High definition quality
  hd,

  /// Ultra high definition quality
  uhd;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ImageQuality.standard:
        return 'standard';
      case ImageQuality.hd:
        return 'hd';
      case ImageQuality.uhd:
        return 'uhd';
    }
  }

  /// Create from string value
  static ImageQuality? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'standard':
        return ImageQuality.standard;
      case 'hd':
        return ImageQuality.hd;
      case 'uhd':
        return ImageQuality.uhd;
      default:
        return null;
    }
  }
}

/// Common image sizes for generation
class ImageSize {
  static const square256 = '256x256';
  static const square512 = '512x512';
  static const square1024 = '1024x1024';
  static const landscape1792x1024 = '1792x1024';
  static const portrait1024x1792 = '1024x1792';
  static const landscape1344x768 = '1344x768';
  static const portrait768x1344 = '768x1344';
  static const landscape1536x640 = '1536x640';
  static const portrait640x1536 = '640x1536';

  /// Get all available standard sizes
  static List<String> get allSizes => [
        square256,
        square512,
        square1024,
        landscape1792x1024,
        portrait1024x1792,
        landscape1344x768,
        portrait768x1344,
        landscape1536x640,
        portrait640x1536,
      ];

  /// Parse size string to dimensions
  static ImageDimensions? parseDimensions(String size) {
    final parts = size.split('x');
    if (parts.length != 2) return null;

    final width = int.tryParse(parts[0]);
    final height = int.tryParse(parts[1]);

    if (width == null || height == null) return null;

    return ImageDimensions(width: width, height: height);
  }

  /// Check if size is square
  static bool isSquare(String size) {
    final dimensions = parseDimensions(size);
    if (dimensions == null) return false;
    return dimensions.width == dimensions.height;
  }

  /// Check if size is landscape
  static bool isLandscape(String size) {
    final dimensions = parseDimensions(size);
    if (dimensions == null) return false;
    return dimensions.width > dimensions.height;
  }

  /// Check if size is portrait
  static bool isPortrait(String size) {
    final dimensions = parseDimensions(size);
    if (dimensions == null) return false;
    return dimensions.width < dimensions.height;
  }
}

/// Image input for editing and variation requests
class ImageInput {
  /// Image data as bytes
  final List<int>? data;

  /// Image URL (for URL-based inputs)
  final String? url;

  /// Image format (png, jpeg, webp, etc.)
  final String? format;

  const ImageInput({
    this.data,
    this.url,
    this.format,
  });

  /// Create from URL
  factory ImageInput.fromUrl(String url, {String? format}) =>
      ImageInput(url: url, format: format);

  /// Create from bytes
  factory ImageInput.fromBytes(List<int> data, {String? format}) =>
      ImageInput(data: data, format: format);

  Map<String, dynamic> toJson() => {
        if (data != null) 'data': data,
        if (url != null) 'url': url,
        if (format != null) 'format': format,
      };

  factory ImageInput.fromJson(Map<String, dynamic> json) => ImageInput(
        data:
            json['data'] != null ? List<int>.from(json['data'] as List) : null,
        url: json['url'] as String?,
        format: json['format'] as String?,
      );

  @override
  String toString() => 'ImageInput('
      'hasData: ${data != null}, '
      'url: $url, '
      'format: $format'
      ')';
}

/// Image edit request model
///
/// Reference: https://platform.openai.com/docs/api-reference/images/createEdit
class ImageEditRequest {
  /// The image to edit. Must be a valid PNG file, less than 4MB, and square.
  /// If mask is not provided, image must have transparency, which will be used as the mask.
  final ImageInput image;

  /// A text description of the desired image(s). The maximum length is 1000 characters.
  final String prompt;

  /// An additional image whose fully transparent areas (e.g. where alpha is zero)
  /// indicate where image should be edited. Must be a valid PNG file, less than 4MB,
  /// and have the same dimensions as image.
  final ImageInput? mask;

  /// The model to use for image generation. Only dall-e-2 is supported at this time.
  final String? model;

  /// The number of images to generate. Must be between 1 and 10.
  final int? count;

  /// The size of the generated images. Must be one of 256x256, 512x512, or 1024x1024.
  final String? size;

  /// The format in which the generated images are returned. Must be one of url or b64_json.
  final String? responseFormat;

  /// A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  final String? user;

  const ImageEditRequest({
    required this.image,
    required this.prompt,
    this.mask,
    this.model,
    this.count,
    this.size,
    this.responseFormat,
    this.user,
  });

  Map<String, dynamic> toJson() => {
        'image': image.toJson(),
        'prompt': prompt,
        if (mask != null) 'mask': mask!.toJson(),
        if (model != null) 'model': model,
        if (count != null) 'n': count,
        if (size != null) 'size': size,
        if (responseFormat != null) 'response_format': responseFormat,
        if (user != null) 'user': user,
      };

  factory ImageEditRequest.fromJson(Map<String, dynamic> json) =>
      ImageEditRequest(
        image: ImageInput.fromJson(json['image'] as Map<String, dynamic>),
        prompt: json['prompt'] as String,
        mask: json['mask'] != null
            ? ImageInput.fromJson(json['mask'] as Map<String, dynamic>)
            : null,
        model: json['model'] as String?,
        count: json['n'] as int?,
        size: json['size'] as String?,
        responseFormat: json['response_format'] as String?,
        user: json['user'] as String?,
      );

  @override
  String toString() => 'ImageEditRequest('
      'prompt: $prompt, '
      'model: $model, '
      'size: $size, '
      'count: $count'
      ')';
}

/// Image variation request model
///
/// Reference: https://platform.openai.com/docs/api-reference/images/createVariation
class ImageVariationRequest {
  /// The image to use as the basis for the variation(s).
  /// Must be a valid PNG file, less than 4MB, and square.
  final ImageInput image;

  /// The model to use for image generation. Only dall-e-2 is supported at this time.
  final String? model;

  /// The number of images to generate. Must be between 1 and 10.
  final int? count;

  /// The size of the generated images. Must be one of 256x256, 512x512, or 1024x1024.
  final String? size;

  /// The format in which the generated images are returned. Must be one of url or b64_json.
  final String? responseFormat;

  /// A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  final String? user;

  const ImageVariationRequest({
    required this.image,
    this.model,
    this.count,
    this.size,
    this.responseFormat,
    this.user,
  });

  Map<String, dynamic> toJson() => {
        'image': image.toJson(),
        if (model != null) 'model': model,
        if (count != null) 'n': count,
        if (size != null) 'size': size,
        if (responseFormat != null) 'response_format': responseFormat,
        if (user != null) 'user': user,
      };

  factory ImageVariationRequest.fromJson(Map<String, dynamic> json) =>
      ImageVariationRequest(
        image: ImageInput.fromJson(json['image'] as Map<String, dynamic>),
        model: json['model'] as String?,
        count: json['n'] as int?,
        size: json['size'] as String?,
        responseFormat: json['response_format'] as String?,
        user: json['user'] as String?,
      );

  @override
  String toString() => 'ImageVariationRequest('
      'model: $model, '
      'size: $size, '
      'count: $count'
      ')';
}

// UsageInfo is imported from chat_provider.dart
