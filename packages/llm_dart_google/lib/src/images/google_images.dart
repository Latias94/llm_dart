import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/google_client.dart';
import '../config/google_config.dart';

class GoogleImages implements ImageGenerationCapability {
  final GoogleClient _client;
  final GoogleConfig _config;
  final LLMLogger _logger;

  GoogleImages(this._client, this._config)
      : _logger = _config.originalConfig == null
            ? const NoopLLMLogger()
            : resolveLogger(_config.originalConfig!);

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    _logger.info('Generating images');

    if (_isImagenModel(request.model ?? _config.model)) {
      return _generateWithImagen(request);
    } else {
      return _generateWithGemini(request);
    }
  }

  Future<ImageGenerationResponse> _generateWithImagen(
    ImageGenerationRequest request,
  ) async {
    final model = request.model ?? _config.model;
    final endpoint = 'models/$model:predict';

    final requestData = {
      'instances': [
        {
          'prompt': request.prompt,
        }
      ],
      'parameters': {
        if (request.count != null) 'sampleCount': request.count,
        if (request.size != null)
          'aspectRatio': _convertSizeToAspectRatio(request.size!),
        'personGeneration': 'allow_adult',
      },
    };

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _parseImagenResponse(response, model);
    } catch (e) {
      _logger.severe('Imagen generation failed: $e', e);
      rethrow;
    }
  }

  Future<ImageGenerationResponse> _generateWithGemini(
    ImageGenerationRequest request,
  ) async {
    final model = request.model ?? _config.model;
    final endpoint = 'models/$model:generateContent';

    final requestData = {
      'contents': [
        {
          'parts': [
            {'text': request.prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': _config.responseModalities ?? ['TEXT', 'IMAGE'],
        if (request.count != null) 'candidateCount': request.count,
        if (_config.maxTokens != null) 'maxOutputTokens': _config.maxTokens,
        if (_config.temperature != null) 'temperature': _config.temperature,
        if (_config.topP != null) 'topP': _config.topP,
        if (_config.topK != null) 'topK': _config.topK,
        if (_config.stopSequences != null)
          'stopSequences': _config.stopSequences,
      },
      if (_config.safetySettings != null)
        'safetySettings':
            _config.safetySettings!.map((s) => s.toJson()).toList(),
    };

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _parseGeminiResponse(response, model);
    } catch (e) {
      _logger.severe('Gemini generation failed: $e', e);
      rethrow;
    }
  }

  ImageGenerationResponse _parseImagenResponse(
    Map<String, dynamic> response,
    String model,
  ) {
    final predictions = response['predictions'] as List? ?? [];
    final images = <GeneratedImage>[];

    for (final prediction in predictions) {
      final predictionMap = prediction as Map<String, dynamic>;
      final imageData = predictionMap['bytesBase64Encoded'] as String?;

      if (imageData != null) {
        final bytes = base64Decode(imageData);

        images.add(
          GeneratedImage(
            data: bytes,
            format: 'png',
          ),
        );
      }
    }

    return ImageGenerationResponse(
      images: images,
      model: model,
    );
  }

  ImageGenerationResponse _parseGeminiResponse(
    Map<String, dynamic> response,
    String model,
  ) {
    final candidates = response['candidates'] as List? ?? [];
    final images = <GeneratedImage>[];
    String? revisedPrompt;

    for (final candidate in candidates) {
      final candidateMap = candidate as Map<String, dynamic>;
      final content = candidateMap['content'] as Map<String, dynamic>? ?? {};
      final parts = content['parts'] as List? ?? [];

      for (final part in parts) {
        final partMap = part as Map<String, dynamic>;

        if (partMap['text'] != null && revisedPrompt == null) {
          revisedPrompt = partMap['text'] as String;
        }

        final inlineData = partMap['inlineData'] as Map<String, dynamic>?;
        if (inlineData != null) {
          final mimeType = inlineData['mimeType'] as String?;
          final data = inlineData['data'] as String?;

          if (data != null) {
            final bytes = base64Decode(data);
            final format = _extractFormatFromMimeType(mimeType);

            images.add(
              GeneratedImage(
                data: bytes,
                format: format,
                revisedPrompt: revisedPrompt,
              ),
            );
          }
        }
      }
    }

    return ImageGenerationResponse(
      images: images,
      model: model,
      revisedPrompt: revisedPrompt,
    );
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    final model = _config.model;
    final endpoint = 'models/$model:generateContent';

    String? imageBase64;
    String? mimeType;

    if (request.image.data != null) {
      imageBase64 = base64Encode(request.image.data!);
      mimeType = _getMimeTypeFromFormat(request.image.format ?? 'png');
    } else if (request.image.url != null) {
      throw UnsupportedError(
        'Google image editing does not support URL inputs, only direct image data',
      );
    }

    if (imageBase64 == null) {
      throw ArgumentError('Image data is required for Google image editing');
    }

    final requestData = {
      'contents': [
        {
          'parts': [
            {'text': request.prompt},
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
        if (request.count != null) 'candidateCount': request.count,
        if (_config.temperature != null) 'temperature': _config.temperature,
      },
      if (_config.safetySettings != null)
        'safetySettings':
            _config.safetySettings!.map((s) => s.toJson()).toList(),
    };

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _parseGeminiResponse(response, model);
    } catch (e) {
      _logger.severe('Google image editing failed: $e');
      rethrow;
    }
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    // Google does not have a direct variation API; we simulate it by
    // asking Gemini to create variations of the provided image.
    final model = _config.model;
    final endpoint = 'models/$model:generateContent';

    String? imageBase64;
    String? mimeType;

    if (request.image.data != null) {
      imageBase64 = base64Encode(request.image.data!);
      mimeType = _getMimeTypeFromFormat(request.image.format ?? 'png');
    } else if (request.image.url != null) {
      throw UnsupportedError(
        'Google image variations do not support URL inputs, only direct image data',
      );
    }

    if (imageBase64 == null) {
      throw ArgumentError('Image data is required for Google image variations');
    }

    final requestData = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Create variations of this image with similar style and content but different details',
            },
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
        if (request.count != null) 'candidateCount': request.count,
        if (_config.temperature != null) 'temperature': _config.temperature,
      },
      if (_config.safetySettings != null)
        'safetySettings':
            _config.safetySettings!.map((s) => s.toJson()).toList(),
    };

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _parseGeminiResponse(response, model);
    } catch (e) {
      _logger.severe('Google image variation failed: $e');
      rethrow;
    }
  }

  @override
  List<String> getSupportedSizes() {
    return ['1:1', '9:16', '16:9', '4:3', '3:4'];
  }

  @override
  List<String> getSupportedFormats() {
    return ['png', 'jpeg', 'webp'];
  }

  @override
  bool get supportsImageEditing => true;

  @override
  bool get supportsImageVariations => true;

  @override
  Future<List<String>> generateImage({
    required String prompt,
    String? model,
    String? negativePrompt,
    String? imageSize,
    int? batchSize,
    String? seed,
    int? numInferenceSteps,
    double? guidanceScale,
    bool? promptEnhancement,
  }) async {
    final response = await generateImages(
      ImageGenerationRequest(
        prompt: prompt,
        model: model,
        negativePrompt: negativePrompt,
        size: imageSize,
        count: batchSize,
        seed: seed != null ? int.tryParse(seed) : null,
        steps: numInferenceSteps,
        guidanceScale: guidanceScale,
        enhancePrompt: promptEnhancement,
      ),
    );

    return response.images
        .where((img) => img.data != null)
        .map((img) =>
            'data:image/${img.format ?? 'png'};base64,${base64Encode(img.data!)}')
        .toList();
  }

  bool _isImagenModel(String model) {
    return model.startsWith('imagen-3');
  }

  String _convertSizeToAspectRatio(String size) {
    switch (size) {
      case 'square':
      case '1:1':
        return '1:1';
      case '9:16':
        return '9:16';
      case '16:9':
        return '16:9';
      case '4:3':
        return '4:3';
      case '3:4':
        return '3:4';
      default:
        return '1:1';
    }
  }

  String _extractFormatFromMimeType(String? mimeType) {
    if (mimeType == null) return 'png';
    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return 'jpeg';
    if (mimeType.contains('webp')) return 'webp';
    return 'png';
  }

  String _getMimeTypeFromFormat(String format) {
    switch (format) {
      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'png':
      default:
        return 'image/png';
    }
  }
}
