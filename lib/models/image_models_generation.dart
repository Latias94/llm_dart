part of 'image_models.dart';

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
