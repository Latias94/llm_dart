import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';

/// Google Images capability implementation
///
/// Supports both Gemini 2.0 Flash Preview Image Generation and Imagen 3 models.
///
/// **Gemini Image Generation:**
/// - Uses conversational approach with responseModalities: ['TEXT', 'IMAGE']
/// - Supports text-to-image and image editing
/// - Model: gemini-2.0-flash-preview-image-generation
///
/// **Imagen 3:**
/// - Dedicated image generation model
/// - Higher quality, specialized for image generation
/// - Model: imagen-3.0-generate-002
///
/// Reference: https://ai.google.dev/gemini-api/docs/image-generation
class GoogleImages implements ImageGenerationCapability {
  final GoogleClient _client;
  final GoogleConfig _config;
  final Logger _logger = Logger('GoogleImages');

  GoogleImages(this._client, this._config);

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    _logger.info('Generating images with prompt: ${request.prompt}');

    // Determine which API to use based on model
    if (_isImagenModel(request.model ?? _config.model)) {
      return _generateWithImagen(request);
    } else {
      return _generateWithGemini(request);
    }
  }

  /// Generate images using Imagen 3 API
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
        // Imagen 3 specific parameters
        'personGeneration': 'allow_adult', // Default safe setting
      },
    };

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _parseImagenResponse(response, model);
    } catch (e) {
      _logger.severe('Imagen generation failed: $e');
      rethrow;
    }
  }

  /// Generate images using Gemini 2.0 Flash Preview Image Generation
  Future<ImageGenerationResponse> _generateWithGemini(
    ImageGenerationRequest request,
  ) async {
    final model = request.model ?? _config.model;
    final endpoint = 'models/$model:generateContent';

    var imageConfig = {
      if (request.size != null)
        'aspectRatio': _normalizeAspectRatio(request.size!),
    };

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
        'imageConfig': imageConfig,
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
      _logger.severe('Gemini generation failed: $e');
      rethrow;
    }
  }

  /// Parse Imagen API response
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
        images.add(GeneratedImage(
          data: bytes,
          format: 'png', // Imagen typically returns PNG
        ));
      }
    }

    return ImageGenerationResponse(
      images: images,
      model: model,
    );
  }

  /// Parse Gemini API response
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

        // Extract text (revised prompt)
        if (partMap['text'] != null && revisedPrompt == null) {
          revisedPrompt = partMap['text'] as String;
        }

        // Extract image data
        final inlineData = partMap['inlineData'] as Map<String, dynamic>?;
        if (inlineData != null) {
          final mimeType = inlineData['mimeType'] as String?;
          final data = inlineData['data'] as String?;

          if (data != null) {
            final bytes = base64Decode(data);
            final format = _extractFormatFromMimeType(mimeType);

            images.add(GeneratedImage(
              data: bytes,
              format: format,
              revisedPrompt: revisedPrompt,
            ));
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
    // Google supports image editing through Gemini conversational approach
    final model = _config.model;
    final endpoint = 'models/$model:generateContent';

    Map<String, dynamic>? imagePart;
    if (request.image.data != null) {
      imagePart = {
        'inlineData': {
          'mimeType': _getMimeTypeFromFormat(request.image.format ?? 'png'),
          'data': base64Encode(request.image.data!),
        }
      };
    } else if (request.image.url != null) {
      final url = request.image.url!;
      imagePart = {
        'fileData': {
          'fileUri': url,
          'mimeType': _getMimeTypeFromFormat(
            request.image.format ?? _guessFormatFromUrl(url) ?? 'png',
          ),
        }
      };
    }

    if (imagePart == null) {
      throw ArgumentError(
        'Image data or URL is required for Google image editing',
      );
    }

    final requestData = {
      'contents': [
        {
          'parts': [
            {'text': request.prompt},
            imagePart,
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
    // Google doesn't have a direct variation API, but we can simulate it
    // by asking Gemini to create variations of the provided image
    final model = _config.model;
    final endpoint = 'models/$model:generateContent';

    Map<String, dynamic>? imagePart;
    if (request.image.data != null) {
      imagePart = {
        'inlineData': {
          'mimeType': _getMimeTypeFromFormat(request.image.format ?? 'png'),
          'data': base64Encode(request.image.data!),
        }
      };
    } else if (request.image.url != null) {
      final url = request.image.url!;
      imagePart = {
        'fileData': {
          'fileUri': url,
          'mimeType': _getMimeTypeFromFormat(
            request.image.format ?? _guessFormatFromUrl(url) ?? 'png',
          ),
        }
      };
    }

    if (imagePart == null) {
      throw ArgumentError(
        'Image data or URL is required for Google image variations',
      );
    }

    final requestData = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Create variations of this image with similar style and content but different details'
            },
            imagePart,
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
    // Google Imagen 3 supports these aspect ratios
    return [
      '1:1', // Square
      '3:4', // Portrait fullscreen
      '4:3', // Fullscreen
      '9:16', // Portrait
      '16:9', // Widescreen
    ];
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

    // For Google, we return base64 data URLs since images are returned as data
    return response.images
        .where((img) => img.data != null)
        .map((img) =>
            'data:image/${img.format ?? 'png'};base64,${base64Encode(img.data!)}')
        .toList();
  }

  /// Check if the model is an Imagen model
  bool _isImagenModel(String model) {
    return model.contains('imagen');
  }

  /// Convert size string to Google's aspect ratio format
  String _convertSizeToAspectRatio(String size) {
    // Handle common size formats
    switch (size.toLowerCase()) {
      case '256x256':
      case '512x512':
      case '1024x1024':
        return '1:1';
      case '768x1344':
      case '1024x1792':
        return '3:4';
      case '1344x768':
      case '1792x1024':
        return '4:3';
      case '640x1536':
        return '9:16';
      case '1536x640':
        return '16:9';
      default:
        // Try to parse and calculate ratio
        final parts = size.split('x');
        if (parts.length == 2) {
          final width = int.tryParse(parts[0]);
          final height = int.tryParse(parts[1]);
          if (width != null && height != null) {
            if (width == height) return '1:1';
            if (width > height) {
              final ratio = width / height;
              if (ratio > 1.7) return '16:9';
              return '4:3';
            } else {
              final ratio = height / width;
              if (ratio > 1.7) return '9:16';
              return '3:4';
            }
          }
        }
        return '1:1'; // Default to square
    }
  }

  /// Normalize an aspect ratio for Google image APIs.
  ///
  /// Google imageConfig expects aspect ratios like `1:1`, `16:9`, etc.
  /// For convenience, we accept common pixel sizes like `1024x1024` and
  /// convert them to the closest supported aspect ratio.
  String _normalizeAspectRatio(String sizeOrRatio) {
    final value = sizeOrRatio.trim();
    if (value.contains(':')) return value;
    if (value.contains('x')) return _convertSizeToAspectRatio(value);
    return value;
  }

  /// Extract format from MIME type
  String _extractFormatFromMimeType(String? mimeType) {
    if (mimeType == null) return 'png';

    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
      return 'jpeg';
    } else if (mimeType.contains('webp')) {
      return 'webp';
    } else {
      return 'png'; // Default
    }
  }

  /// Get MIME type from format
  String _getMimeTypeFromFormat(String format) {
    switch (format.toLowerCase()) {
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

  String? _guessFormatFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';
    return null;
  }
}
