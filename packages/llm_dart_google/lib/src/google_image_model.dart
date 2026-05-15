import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_image_editing.dart';
import 'google_model_describer.dart';
import 'google_options.dart';
import 'google_shared.dart';

final class GoogleImageModel implements ImageModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final GoogleImageModelSettings settings;

  @override
  final String modelId;

  GoogleImageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const GoogleImageModelSettings(),
  })  : settings = _resolveSettings(settings),
        baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerId => 'google';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeGoogleImageModel(
      modelId,
      settings: settings,
    );
  }

  bool get isGeminiImageModel => _isGeminiImageModel(modelId);

  int get maxImagesPerCall =>
      settings.maxImagesPerCall ?? (isGeminiImageModel ? 1 : 4);

  Uri get predictUri =>
      Uri.parse('${_normalizedBaseUrl()}/models/$modelId:predict');

  Uri get generateContentUri =>
      Uri.parse('${_normalizedBaseUrl()}/models/$modelId:generateContent');

  @override
  Future<ImageGenerationResult> doGenerate(
    ImageGenerationRequest request,
  ) async {
    final options = _resolveProviderOptions(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
    );
    _validateRequest(request, options);

    final response = await transport.send(
      TransportRequest(
        uri: isGeminiImageModel ? generateContentUri : predictUri,
        method: TransportMethod.post,
        headers: {
          'x-goog-api-key': apiKey,
          'content-type': 'application/json',
          'accept': 'application/json',
          ...settings.headers,
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: isGeminiImageModel
            ? _buildGeminiRequest(request, options: options)
            : _buildImagenRequest(request, options: options),
        timeout: request.callOptions.timeout,
        maxRetries: request.callOptions.maxRetries,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    final json = _decodeJsonObject(response.body);
    return isGeminiImageModel
        ? _decodeGeminiResponse(json, headers: response.headers)
        : _decodeImagenResponse(json, headers: response.headers);
  }

  Future<ImageGenerationResult> edit(GoogleImageEditRequest request) async {
    _validateGeminiEditSupport();
    final options = _resolveProviderOptions(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
    );
    _validateEditRequest(request, options);

    final response = await transport.send(
      TransportRequest(
        uri: generateContentUri,
        method: TransportMethod.post,
        headers: {
          'x-goog-api-key': apiKey,
          'content-type': 'application/json',
          'accept': 'application/json',
          ...settings.headers,
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: _buildGeminiEditRequest(request, options: options),
        timeout: request.callOptions.timeout,
        maxRetries: request.callOptions.maxRetries,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _decodeGeminiResponse(
      _decodeJsonObject(response.body),
      headers: response.headers,
    );
  }

  Future<ImageGenerationResult> createVariation(
    GoogleImageVariationRequest request,
  ) {
    return edit(
      GoogleImageEditRequest(
        prompt: request.prompt,
        images: request.images,
        count: request.count,
        callOptions: request.callOptions,
      ),
    );
  }

  void _validateRequest(
    ImageGenerationRequest request,
    GoogleImageOptions? options,
  ) {
    if (request.size != null) {
      throw ArgumentError.value(
        request.size,
        'request.size',
        'Google image models do not support request.size. Use GoogleImageOptions.aspectRatio instead.',
      );
    }

    if (isGeminiImageModel && request.count != 1) {
      throw ArgumentError.value(
        request.count,
        'request.count',
        'Gemini image models currently support only count=1. Use an Imagen model for multi-image generation.',
      );
    }

    if (request.count > maxImagesPerCall) {
      throw ArgumentError.value(
        request.count,
        'request.count',
        'Google image models currently support at most $maxImagesPerCall generated images per call.',
      );
    }

    if (isGeminiImageModel && options?.personGeneration != null) {
      throw ArgumentError.value(
        options?.personGeneration,
        'request.callOptions.providerOptions.personGeneration',
        'GoogleImageOptions.personGeneration is only supported for Imagen image models.',
      );
    }

    final safetySettings = _resolveSafetySettings(options);
    if (!isGeminiImageModel && safetySettings.isNotEmpty) {
      throw ArgumentError.value(
        safetySettings,
        'request.callOptions.providerOptions.safetySettings',
        'Google safety settings are only supported for Gemini image models. Imagen safety filters are not configurable through this surface.',
      );
    }
  }

  void _validateGeminiEditSupport() {
    if (!isGeminiImageModel) {
      throw UnsupportedError(
        'Google image editing currently requires Gemini image models. Imagen models remain generation-only on this provider-owned helper surface.',
      );
    }
  }

  void _validateEditRequest(
    GoogleImageEditRequest request,
    GoogleImageOptions? options,
  ) {
    if (request.images.isEmpty) {
      throw ArgumentError.value(
        request.images,
        'request.images',
        'Google image editing requires at least one image input.',
      );
    }

    if (request.count != 1) {
      throw ArgumentError.value(
        request.count,
        'request.count',
        'Gemini image editing currently supports only count=1.',
      );
    }

    if (options?.personGeneration != null) {
      throw ArgumentError.value(
        options?.personGeneration,
        'request.callOptions.providerOptions.personGeneration',
        'GoogleImageOptions.personGeneration is only supported for Imagen image generation, not Gemini image editing.',
      );
    }

    for (var index = 0; index < request.images.length; index += 1) {
      final image = request.images[index];
      if (!image.mediaType.startsWith('image/')) {
        throw ArgumentError.value(
          image.mediaType,
          'request.images[$index].mediaType',
          'Google image editing inputs must use an image/* media type.',
        );
      }

      if ((image.bytes == null) == (image.uri == null)) {
        throw ArgumentError.value(
          image,
          'request.images[$index]',
          'Google image editing inputs must provide either bytes or a URI.',
        );
      }
    }
  }

  Map<String, Object?> _buildImagenRequest(
    ImageGenerationRequest request, {
    required GoogleImageOptions? options,
  }) {
    return {
      'instances': [
        {
          'prompt': request.prompt,
        },
      ],
      'parameters': {
        'sampleCount': request.count,
        if (options?.aspectRatio case final aspectRatio?)
          'aspectRatio': aspectRatio.value,
        if (options?.personGeneration case final personGeneration?)
          'personGeneration': personGeneration.value,
      },
    };
  }

  Map<String, Object?> _buildGeminiRequest(
    ImageGenerationRequest request, {
    required GoogleImageOptions? options,
  }) {
    final safetySettings = _resolveSafetySettings(options);
    return {
      'contents': [
        {
          'parts': [
            {
              'text': request.prompt,
            },
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': [
          GoogleResponseModality.text.value,
          GoogleResponseModality.image.value,
        ],
        if (options?.aspectRatio case final aspectRatio?)
          'imageConfig': {
            'aspectRatio': aspectRatio.value,
          },
      },
      if (safetySettings.isNotEmpty)
        'safetySettings': [
          for (final setting in safetySettings) setting.toJson(),
        ],
    };
  }

  Map<String, Object?> _buildGeminiEditRequest(
    GoogleImageEditRequest request, {
    required GoogleImageOptions? options,
  }) {
    final safetySettings = _resolveSafetySettings(options);
    return {
      'contents': [
        {
          'parts': [
            {
              'text': request.prompt,
            },
            for (final image in request.images) _encodeEditInput(image),
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': [
          GoogleResponseModality.text.value,
          GoogleResponseModality.image.value,
        ],
        if (options?.aspectRatio case final aspectRatio?)
          'imageConfig': {
            'aspectRatio': aspectRatio.value,
          },
      },
      if (safetySettings.isNotEmpty)
        'safetySettings': [
          for (final setting in safetySettings) setting.toJson(),
        ],
    };
  }

  Map<String, Object?> _encodeEditInput(GoogleImageEditInput input) {
    if (input.bytes case final bytes?) {
      return {
        'inlineData': {
          'mimeType': input.mediaType,
          'data': base64Encode(bytes),
        },
      };
    }

    return {
      'fileData': {
        'mimeType': input.mediaType,
        'fileUri': input.uri.toString(),
      },
    };
  }

  List<GoogleSafetySetting> _resolveSafetySettings(
      GoogleImageOptions? options) {
    return options?.safetySettings ?? settings.safetySettings;
  }

  GoogleImageOptions? _resolveProviderOptions(
    CallOptions callOptions, {
    required String parameterName,
  }) {
    return resolveProviderInvocationOptions<GoogleImageOptions>(
      callOptions.providerOptions,
      parameterName: parameterName,
      expectedTypeName: 'GoogleImageOptions',
      usageContext: 'Google image models',
    );
  }

  ImageGenerationResult _decodeImagenResponse(
    Map<String, Object?> json, {
    required Map<String, String> headers,
  }) {
    final predictions = asList(json['predictions']);
    if (predictions.isEmpty) {
      throw StateError(
        'Expected a Google Imagen response with at least one prediction.',
      );
    }

    final images = <GeneratedImage>[];
    for (var index = 0; index < predictions.length; index += 1) {
      final prediction = asMap(predictions[index]);
      final bytes = decodeBase64(asString(prediction?['bytesBase64Encoded']));
      if (bytes == null || bytes.isEmpty) {
        throw StateError(
          'Expected Google Imagen prediction $index to contain bytesBase64Encoded.',
        );
      }

      images.add(
        GeneratedImage(
          bytes: bytes,
          mediaType: 'image/png',
        ),
      );
    }

    return ImageGenerationResult(
      images: images,
      responseMetadata: ModelResponseMetadata(
        timestamp: DateTime.now().toUtc(),
        modelId: modelId,
        headers: headers,
      ),
      providerMetadata: googleProviderMetadata(
        {
          'generationApi': 'predict',
        },
      ),
    );
  }

  ImageGenerationResult _decodeGeminiResponse(
    Map<String, Object?> json, {
    required Map<String, String> headers,
  }) {
    final candidates = asList(json['candidates']);
    if (candidates.isEmpty) {
      throw StateError(
        'Expected a Google Gemini image response with at least one candidate.',
      );
    }

    final images = <GeneratedImage>[];
    final revisedPrompts = <String>[];
    final finishReasons = <String>[];

    for (var index = 0; index < candidates.length; index += 1) {
      final candidate = asMap(candidates[index]);
      if (candidate == null) {
        throw StateError(
          'Expected Google Gemini image candidate $index to be a JSON object.',
        );
      }

      final finishReason = asString(candidate['finishReason']);
      if (finishReason != null && finishReason.isNotEmpty) {
        finishReasons.add(finishReason);
      }

      final content = asMap(candidate['content']);
      final parts = asList(content?['parts']);
      final textParts = <String>[];

      for (final partValue in parts) {
        final part = asMap(partValue);
        if (part == null) {
          continue;
        }

        final text = asString(part['text']);
        if (text != null && text.isNotEmpty) {
          textParts.add(text);
        }

        final inlineData = asMap(part['inlineData']);
        final bytes = decodeBase64(asString(inlineData?['data']));
        if (bytes == null || bytes.isEmpty) {
          continue;
        }

        images.add(
          GeneratedImage(
            bytes: bytes,
            mediaType: asString(inlineData?['mimeType']) ?? 'image/png',
          ),
        );
      }

      if (textParts.isNotEmpty) {
        revisedPrompts.add(textParts.join('\n'));
      }
    }

    if (images.isEmpty) {
      throw StateError(
        'Expected Google Gemini image generation to return image bytes.',
      );
    }

    return ImageGenerationResult(
      images: images,
      usage: decodeGoogleUsage(asMap(json['usageMetadata'])),
      responseMetadata: ModelResponseMetadata(
        timestamp: DateTime.now().toUtc(),
        modelId: modelId,
        headers: headers,
      ),
      providerMetadata: googleProviderMetadata(
        {
          'generationApi': 'generateContent',
          if (asString(json['modelVersion']) case final modelVersion?)
            'modelVersion': modelVersion,
          if (asMap(json['promptFeedback']) case final promptFeedback?)
            'promptFeedback': normalizeJsonValue(promptFeedback),
          if (asMap(json['usageMetadata']) case final usageMetadata?)
            'usage': normalizeJsonValue(usageMetadata),
          if (revisedPrompts.isNotEmpty) 'revisedPrompts': revisedPrompts,
          if (finishReasons.isNotEmpty) 'finishReasons': finishReasons,
        },
      ),
    );
  }

  Map<String, Object?> _decodeJsonObject(Object? body) {
    if (body is Map<String, Object?>) {
      return body;
    }

    if (body is Map) {
      return Map<String, Object?>.from(body);
    }

    if (body is String) {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    }

    throw StateError(
      'Expected a Google image JSON object response but received ${body.runtimeType}.',
    );
  }

  String _normalizedBaseUrl() {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  static GoogleImageModelSettings _resolveSettings(
      ProviderModelOptions settings) {
    return resolveProviderModelOptions<GoogleImageModelSettings>(
      settings,
      parameterName: 'settings',
      expectedTypeName: 'GoogleImageModelSettings',
      usageContext: 'Google image models',
    );
  }
}

bool _isGeminiImageModel(String modelId) {
  return modelId.toLowerCase().contains('gemini');
}
