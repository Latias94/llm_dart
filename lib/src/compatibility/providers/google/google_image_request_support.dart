part of 'google_image_support.dart';

final class _GoogleImageRequestSupport {
  static const _formatSupport = _GoogleImageFormatSupport();

  const _GoogleImageRequestSupport();

  Map<String, dynamic> buildImagenRequest(
    ImageGenerationRequest request,
  ) {
    return {
      'instances': [
        {
          'prompt': request.prompt,
        }
      ],
      'parameters': {
        if (request.count != null) 'sampleCount': request.count,
        if (request.size != null)
          'aspectRatio': _formatSupport.convertSizeToAspectRatio(
            request.size!,
          ),
        'personGeneration': 'allow_adult',
      },
    };
  }

  Map<String, dynamic> buildGeminiRequest(
    ImageGenerationRequest request,
    GoogleConfig config,
  ) {
    final imageConfig = <String, dynamic>{
      if (request.size != null) 'aspectRatio': request.size!,
    };

    return {
      'contents': [
        {
          'parts': [
            {'text': request.prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': config.responseModalities ?? ['TEXT', 'IMAGE'],
        'imageConfig': imageConfig,
        if (request.count != null) 'candidateCount': request.count,
        if (config.maxTokens != null) 'maxOutputTokens': config.maxTokens,
        if (config.temperature != null) 'temperature': config.temperature,
        if (config.topP != null) 'topP': config.topP,
        if (config.topK != null) 'topK': config.topK,
        if (config.stopSequences != null) 'stopSequences': config.stopSequences,
      },
      if (config.safetySettings != null)
        'safetySettings':
            config.safetySettings!.map((setting) => setting.toJson()).toList(),
    };
  }

  Map<String, dynamic> buildGeminiInlineImageRequest({
    required String prompt,
    required String imageBase64,
    required String mimeType,
    required GoogleConfig config,
    int? count,
  }) {
    return {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': imageBase64,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        if (count != null) 'candidateCount': count,
        if (config.temperature != null) 'temperature': config.temperature,
      },
      if (config.safetySettings != null)
        'safetySettings':
            config.safetySettings!.map((setting) => setting.toJson()).toList(),
    };
  }
}
