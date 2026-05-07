part of 'openai_image_support.dart';

final class _OpenAIImageRequestSupport {
  const _OpenAIImageRequestSupport();

  Map<String, dynamic> buildGenerationRequest(
    ImageGenerationRequest request, {
    required OpenAIConfig config,
  }) {
    return {
      'model': request.model ?? config.model,
      'prompt': request.prompt,
      if (request.negativePrompt != null)
        'negative_prompt': request.negativePrompt,
      if (request.size != null) 'size': request.size,
      if (request.count != null) 'n': request.count,
      if (request.seed != null) 'seed': request.seed,
      if (request.steps != null) 'num_inference_steps': request.steps,
      if (request.guidanceScale != null)
        'guidance_scale': request.guidanceScale,
      if (request.enhancePrompt != null)
        'prompt_enhancement': request.enhancePrompt,
      if (request.style != null) 'style': request.style,
      if (request.quality != null) 'quality': request.quality,
    };
  }
}
