import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_image_editing.dart';
import 'openai_model_describer.dart';
import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

final class OpenAIImageModel implements ImageModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIImageModelSettings settings;

  @override
  final String modelId;

  OpenAIImageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAIImageModelSettings(),
  })  : settings = resolveOpenAIModelSettings(
          settings,
          parameterName: 'settings',
          expectedTypeName:
              'OpenAIImageModelSettings for OpenAI-family image models',
        ),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAIImageModel(
      modelId,
      profile: profile,
    );
  }

  int get maxImagesPerCall => _maxImagesPerCall(modelId);

  Uri get imageGenerationUri => Uri.parse('$baseUrl/images/generations');
  Uri get imageEditUri => Uri.parse('$baseUrl/images/edits');

  Map<String, String> get defaultHeaders => buildOpenAIFamilyDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        organization: settings.organization,
        project: settings.project,
        headers: settings.headers,
      );

  @override
  Future<ImageGenerationResult> doGenerate(
    ImageGenerationRequest request,
  ) async {
    final options = _resolveProviderOptions(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
    );
    _validateGenerationRequest(request, options);

    final response = await transport.send(
      _buildGenerationTransportRequest(
        request,
        options: options,
      ),
    );

    return _decodeResponse(
      response.body,
      headers: response.headers,
      requestedResponseFormat: _shouldIncludeResponseFormat(modelId)
          ? (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
          : null,
    );
  }

  Future<ImageGenerationResult> edit(OpenAIImageEditRequest request) async {
    final options = _resolveProviderOptions(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
    );
    _validateEditRequest(request, options);

    final response = await transport.send(
      _buildEditTransportRequest(
        request,
        options: options,
      ),
    );

    return _decodeResponse(
      response.body,
      headers: response.headers,
      requestedResponseFormat: options?.responseFormat,
    );
  }

  TransportRequest _buildGenerationTransportRequest(
    ImageGenerationRequest request, {
    required OpenAIImageOptions? options,
  }) {
    return TransportRequest(
      uri: imageGenerationUri,
      method: TransportMethod.post,
      headers: {
        ...defaultHeaders,
        'content-type': 'application/json',
        'accept': 'application/json',
        if (request.callOptions.headers case final headers?) ...headers,
      },
      body: {
        'model': modelId,
        'prompt': request.prompt,
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
        if (_shouldIncludeResponseFormat(modelId))
          'response_format':
              (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
                  .value,
      },
      timeout: request.callOptions.timeout,
      maxRetries: request.callOptions.maxRetries,
      cancellation: request.callOptions.cancellation,
      responseType: TransportResponseType.json,
    );
  }

  TransportRequest _buildEditTransportRequest(
    OpenAIImageEditRequest request, {
    required OpenAIImageOptions? options,
  }) {
    final outputCompression =
        request.outputCompression ?? options?.outputCompression;
    final multipart = buildTransportMultipartBody(
      fields: [
        TransportMultipartField.text(
          name: 'model',
          value: modelId,
        ),
        TransportMultipartField.text(
          name: 'prompt',
          value: request.prompt,
        ),
        for (final image in request.images)
          TransportMultipartField.file(
            name: 'image',
            filename: image.filename ?? _buildImageFilename(image.mediaType),
            mediaType: image.mediaType,
            bytes: image.bytes,
          ),
        if (request.mask case final mask?)
          TransportMultipartField.file(
            name: 'mask',
            filename: mask.filename ?? 'mask.png',
            mediaType: mask.mediaType,
            bytes: mask.bytes,
          ),
        TransportMultipartField.text(
          name: 'n',
          value: request.count.toString(),
        ),
        if (request.size case final size?)
          TransportMultipartField.text(
            name: 'size',
            value: size,
          ),
        if (options?.background case final background?)
          TransportMultipartField.text(
            name: 'background',
            value: background.value,
          ),
        if (request.inputFidelity case final inputFidelity?)
          TransportMultipartField.text(
            name: 'input_fidelity',
            value: inputFidelity.value,
          ),
        if (request.partialImages case final partialImages?)
          TransportMultipartField.text(
            name: 'partial_images',
            value: partialImages.toString(),
          ),
        if (options?.quality case final quality?)
          TransportMultipartField.text(
            name: 'quality',
            value: quality.value,
          ),
        if (outputCompression != null)
          TransportMultipartField.text(
            name: 'output_compression',
            value: outputCompression.toString(),
          ),
        if (options?.outputFormat case final outputFormat?)
          TransportMultipartField.text(
            name: 'output_format',
            value: outputFormat.value,
          ),
        if (options?.responseFormat case final responseFormat?)
          TransportMultipartField.text(
            name: 'response_format',
            value: responseFormat.value,
          ),
        if (options?.user case final user?)
          TransportMultipartField.text(
            name: 'user',
            value: user,
          ),
      ],
    );

    return TransportRequest(
      uri: imageEditUri,
      method: TransportMethod.post,
      headers: {
        ...defaultHeaders,
        'content-type': multipart.contentType,
        'accept': 'application/json',
        if (request.callOptions.headers case final headers?) ...headers,
      },
      body: multipart.bytes,
      timeout: request.callOptions.timeout,
      maxRetries: request.callOptions.maxRetries,
      cancellation: request.callOptions.cancellation,
      responseType: TransportResponseType.json,
    );
  }

  ImageGenerationResult _decodeResponse(
    Object? body, {
    required Map<String, String> headers,
    required OpenAIImageResponseFormat? requestedResponseFormat,
  }) {
    final json = decodeOpenAIJsonObject(
      body,
      responseName: 'image generation',
    );
    final data = json['data'];
    if (data is! List) {
      throw StateError(
        'Expected an OpenAI image generation response with a data list.',
      );
    }

    final outputFormat = openAIStringOrNull(json['output_format']);
    final revisedPrompts = <String>[];
    final images = <GeneratedImage>[];
    final imageMetadata = <Map<String, Object?>>[];
    final usage = _decodeUsage(json['usage']);
    final usageDetails = _usageDetails(json['usage']);

    for (var index = 0; index < data.length; index += 1) {
      final item = data[index];
      if (item is! Map) {
        throw StateError(
          'Expected OpenAI image item $index to be a JSON object.',
        );
      }

      final map = Map<String, Object?>.from(item);
      final revisedPrompt = openAIStringOrNull(map['revised_prompt']);
      if (revisedPrompt != null && revisedPrompt.isNotEmpty) {
        revisedPrompts.add(revisedPrompt);
      }
      imageMetadata.add(
        _imageMetadata(
          json,
          item: map,
          outputFormat: outputFormat,
          tokenDetails: usageDetails,
          index: index,
          total: data.length,
        ),
      );

      final b64Json = openAIStringOrNull(map['b64_json']);
      final url = openAIStringOrNull(map['url']);
      if (b64Json == null && url == null) {
        throw StateError(
          'Expected OpenAI image item $index to contain either b64_json or url.',
        );
      }

      images.add(
        GeneratedImage(
          uri: url == null ? null : Uri.tryParse(url),
          bytes: b64Json == null ? null : base64Decode(b64Json),
          mediaType:
              b64Json == null ? null : _mediaTypeForOutputFormat(outputFormat),
        ),
      );
    }

    if (images.isEmpty) {
      throw StateError('Expected OpenAI image generation to return images.');
    }

    return ImageGenerationResult(
      images: images,
      usage: usage,
      responseMetadata: ModelResponseMetadata(
        timestamp: DateTime.now().toUtc(),
        modelId: modelId,
        headers: headers,
      ),
      providerMetadata: ProviderMetadata.forNamespace(
        'openai',
        {
          'images': imageMetadata,
          if (json['created'] != null) 'created': json['created'],
          if (json['size'] != null) 'size': json['size'],
          if (json['quality'] != null) 'quality': json['quality'],
          if (json['background'] != null) 'background': json['background'],
          if (json['output_format'] != null)
            'outputFormat': json['output_format'],
          if (requestedResponseFormat != null)
            'responseFormat': requestedResponseFormat.value,
          if (revisedPrompts.isNotEmpty) 'revisedPrompts': revisedPrompts,
          if (json['usage'] != null) 'usage': json['usage'],
        },
      ),
    );
  }

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

  void _validateGenerationRequest(
    ImageGenerationRequest request,
    OpenAIImageOptions? options,
  ) {
    if (request.count < 1) {
      throw ArgumentError.value(
        request.count,
        'request.count',
        'OpenAI image generation requires count >= 1.',
      );
    }

    final maxImagesPerCall = this.maxImagesPerCall;
    if (request.count > maxImagesPerCall) {
      throw ArgumentError.value(
        request.count,
        'request.count',
        'OpenAI image model $modelId supports at most $maxImagesPerCall generated images per call.',
      );
    }

    if (options?.outputCompression case final outputCompression?) {
      _validateOutputCompression(
        outputCompression,
        'request.callOptions.providerOptions.outputCompression',
      );
    }
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

    if (request.outputCompression case final outputCompression?) {
      _validateOutputCompression(
        outputCompression,
        'request.outputCompression',
      );
    }

    if (options?.style != null) {
      throw ArgumentError.value(
        options?.style,
        'request.callOptions.providerOptions.style',
        'OpenAIImageOptions.style is only supported for image generation, not image editing.',
      );
    }

    if (options?.moderation != null) {
      throw ArgumentError.value(
        options?.moderation,
        'request.callOptions.providerOptions.moderation',
        'OpenAIImageOptions.moderation is only supported for image generation, not image editing.',
      );
    }

    if (options?.outputCompression case final outputCompression?) {
      _validateOutputCompression(
        outputCompression,
        'request.callOptions.providerOptions.outputCompression',
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

UsageStats? _decodeUsage(Object? value) {
  final map = _asOpenAIMap(value);
  if (map == null) {
    return null;
  }

  final usage = UsageStats(
    inputTokens: openAIIntOrNull(map['input_tokens']),
    outputTokens: openAIIntOrNull(map['output_tokens']),
    totalTokens: openAIIntOrNull(map['total_tokens']),
  );

  return usage.isEmpty ? null : usage;
}

Map<String, Object?>? _usageDetails(Object? value) {
  final map = _asOpenAIMap(value);
  return _asOpenAIMap(map?['input_tokens_details']);
}

Map<String, Object?> _imageMetadata(
  Map<String, Object?> response, {
  required Map<String, Object?> item,
  required String? outputFormat,
  required Map<String, Object?>? tokenDetails,
  required int index,
  required int total,
}) {
  return {
    if (openAIStringOrNull(item['revised_prompt']) case final revisedPrompt?
        when revisedPrompt.isNotEmpty)
      'revisedPrompt': revisedPrompt,
    if (response['created'] != null) 'created': response['created'],
    if (response['size'] != null) 'size': response['size'],
    if (response['quality'] != null) 'quality': response['quality'],
    if (response['background'] != null) 'background': response['background'],
    if (outputFormat != null) 'outputFormat': outputFormat,
    ..._distributeTokenDetails(
      tokenDetails,
      index: index,
      total: total,
    ),
  };
}

Map<String, Object?> _distributeTokenDetails(
  Map<String, Object?>? details, {
  required int index,
  required int total,
}) {
  if (details == null || total < 1) {
    return const {};
  }

  final result = <String, Object?>{};
  final imageTokens = openAIIntOrNull(details['image_tokens']);
  if (imageTokens != null) {
    result['imageTokens'] = _distributedTokenCount(
      imageTokens,
      index: index,
      total: total,
    );
  }

  final textTokens = openAIIntOrNull(details['text_tokens']);
  if (textTokens != null) {
    result['textTokens'] = _distributedTokenCount(
      textTokens,
      index: index,
      total: total,
    );
  }

  return result;
}

int _distributedTokenCount(
  int value, {
  required int index,
  required int total,
}) {
  final base = value ~/ total;
  final remainder = value - base * (total - 1);
  return index == total - 1 ? remainder : base;
}

Map<String, Object?>? _asOpenAIMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

void _validateOutputCompression(int outputCompression, String parameterName) {
  if (outputCompression < 0 || outputCompression > 100) {
    throw ArgumentError.value(
      outputCompression,
      parameterName,
      'OpenAI image outputCompression must be between 0 and 100.',
    );
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
    'gpt-image-2',
  ];

  return defaultResponseFormatPrefixes.any(modelId.startsWith);
}

int _maxImagesPerCall(String modelId) {
  return switch (modelId) {
    'dall-e-2' => 10,
    'dall-e-3' => 1,
    'chatgpt-image-latest' => 10,
    'gpt-image-1' => 10,
    'gpt-image-1-mini' => 10,
    'gpt-image-1.5' => 10,
    'gpt-image-2' => 10,
    _ => 1,
  };
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
