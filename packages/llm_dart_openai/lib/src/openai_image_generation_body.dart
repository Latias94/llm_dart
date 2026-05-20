import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_model_capabilities.dart';
import 'openai_image_options.dart';
import 'openai_image_types.dart';

Map<String, Object?> buildOpenAIImageGenerationRequestBody({
  required String modelId,
  required ImageGenerationRequest request,
  required OpenAIImageOptions? options,
}) {
  return {
    'model': modelId,
    'prompt': request.prompt!,
    'n': request.count,
    if (request.size != null) 'size': request.size,
    if (options?.style case final style?) 'style': style.value,
    if (options?.quality case final quality?) 'quality': quality.value,
    if (options?.background case final background?)
      'background': background.value,
    if (options?.moderation case final moderation?)
      'moderation': moderation.value,
    if (options?.outputFormat case final outputFormat?)
      'output_format': outputFormat.value,
    if (options?.outputCompression case final outputCompression?)
      'output_compression': outputCompression,
    if (options?.user case final user?) 'user': user,
    if (shouldIncludeOpenAIImageResponseFormat(modelId))
      'response_format':
          (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
              .value,
  };
}
