part of 'openai_image_model.dart';

extension _OpenAIImageSupport on OpenAIImageModel {
  OpenAIImageOptions? _resolveProviderOptions(
    CallOptions callOptions, {
    required String parameterName,
  }) {
    return resolveOpenAIProviderOptions<OpenAIImageOptions>(
      callOptions,
      parameterName: parameterName,
      expectedTypeName: 'OpenAIImageOptions for OpenAI-family image models',
    );
  }

  void _validateEditRequest(
    OpenAIImageEditRequest request,
    OpenAIImageOptions? options,
  ) {
    if (request.prompt.trim().isEmpty) {
      throw ArgumentError.value(
        request.prompt,
        'request.prompt',
        'OpenAI image editing requires a non-empty prompt.',
      );
    }

    if (request.images.isEmpty) {
      throw ArgumentError.value(
        request.images,
        'request.images',
        'OpenAI image editing requires at least one image input.',
      );
    }

    if (request.count < 1) {
      throw ArgumentError.value(
        request.count,
        'request.count',
        'OpenAI image editing requires count >= 1.',
      );
    }

    if (request.partialImages case final partialImages?
        when partialImages < 1) {
      throw ArgumentError.value(
        partialImages,
        'request.partialImages',
        'OpenAI image editing partialImages must be >= 1.',
      );
    }

    if (request.outputCompression case final outputCompression?
        when outputCompression < 0 || outputCompression > 100) {
      throw ArgumentError.value(
        outputCompression,
        'request.outputCompression',
        'OpenAI image editing outputCompression must be between 0 and 100.',
      );
    }

    if (options?.style != null) {
      throw ArgumentError.value(
        options?.style,
        'request.callOptions.providerOptions.style',
        'OpenAIImageOptions.style is only supported for image generation, not image editing.',
      );
    }

    for (var index = 0; index < request.images.length; index += 1) {
      _validateEditInput(
        request.images[index],
        'request.images[$index]',
      );
    }

    if (request.mask case final mask?) {
      _validateEditInput(
        mask,
        'request.mask',
      );
    }
  }

  void _validateEditInput(
    OpenAIImageEditInput input,
    String parameterName,
  ) {
    if (input.bytes.isEmpty) {
      throw ArgumentError.value(
        input.bytes,
        '$parameterName.bytes',
        'OpenAI image editing inputs must provide non-empty bytes.',
      );
    }

    if (!input.mediaType.startsWith('image/')) {
      throw ArgumentError.value(
        input.mediaType,
        '$parameterName.mediaType',
        'OpenAI image editing inputs must use an image/* media type.',
      );
    }
  }
}

bool _shouldIncludeResponseFormat(String modelId) {
  return !_hasDefaultResponseFormat(modelId);
}

bool _hasDefaultResponseFormat(String modelId) {
  const defaultResponseFormatPrefixes = [
    'chatgpt-image-',
    'gpt-image-1-mini',
    'gpt-image-1.5',
    'gpt-image-1',
  ];

  return defaultResponseFormatPrefixes.any(modelId.startsWith);
}

String _mediaTypeForOutputFormat(String? outputFormat) {
  return switch (outputFormat) {
    'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'image/png',
  };
}

String _buildImageFilename(String mediaType) {
  final normalized = mediaType.split(';').first.trim().toLowerCase();
  final extension = switch (normalized) {
    'image/png' => 'png',
    'image/jpeg' => 'jpeg',
    'image/jpg' => 'jpg',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'bin',
  };

  return 'image.$extension';
}
