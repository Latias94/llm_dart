import 'image_models_primitives.dart';

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
