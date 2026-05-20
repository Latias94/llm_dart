import 'openai_builtin_tool.dart';
import '../image/openai_image_types.dart';

enum OpenAIImageGenerationInputFidelity {
  low('low'),
  high('high');

  const OpenAIImageGenerationInputFidelity(this.value);

  final String value;
}

enum OpenAIImageGenerationModeration {
  auto('auto');

  const OpenAIImageGenerationModeration(this.value);

  final String value;
}

enum OpenAIImageGenerationSize {
  auto('auto'),
  square1024('1024x1024'),
  portrait1024x1536('1024x1536'),
  landscape1536x1024('1536x1024');

  const OpenAIImageGenerationSize(this.value);

  final String value;
}

final class OpenAIImageMask {
  final String? fileId;
  final Uri? imageUrl;

  const OpenAIImageMask({
    this.fileId,
    this.imageUrl,
  }) : assert(
          fileId != null || imageUrl != null,
          'OpenAIImageMask needs either a fileId or an imageUrl.',
        );

  Map<String, Object?> toJson() {
    return {
      if (fileId != null) 'file_id': fileId,
      if (imageUrl != null) 'image_url': imageUrl.toString(),
    };
  }
}

final class OpenAIImageGenerationTool implements OpenAIBuiltInTool {
  final OpenAIImageBackground? background;
  final OpenAIImageGenerationInputFidelity? inputFidelity;
  final OpenAIImageMask? inputImageMask;
  final String? model;
  final OpenAIImageGenerationModeration? moderation;
  final int? partialImages;
  final OpenAIImageQuality? quality;
  final int? outputCompression;
  final OpenAIImageOutputFormat? outputFormat;
  final OpenAIImageGenerationSize? size;
  final Map<String, Object?>? parameters;

  const OpenAIImageGenerationTool({
    this.background,
    this.inputFidelity,
    this.inputImageMask,
    this.model,
    this.moderation,
    this.partialImages,
    this.quality,
    this.outputCompression,
    this.outputFormat,
    this.size,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.imageGeneration;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'image_generation',
      if (background != null) 'background': background!.value,
      if (inputFidelity != null) 'input_fidelity': inputFidelity!.value,
      if (inputImageMask != null) 'input_image_mask': inputImageMask!.toJson(),
      if (model != null) 'model': model,
      if (moderation != null) 'moderation': moderation!.value,
      if (partialImages != null) 'partial_images': partialImages,
      if (quality != null) 'quality': quality!.value,
      if (outputCompression != null) 'output_compression': outputCompression,
      if (outputFormat != null) 'output_format': outputFormat!.value,
      if (size != null) 'size': size!.value,
      if (parameters != null) ...parameters!,
    };
  }
}
