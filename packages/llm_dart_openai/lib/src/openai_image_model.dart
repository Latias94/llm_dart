import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_options.dart';

final class OpenAIImageModel implements ImageModel {
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
  })  : settings = _resolveSettings(settings),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  Uri get imageGenerationUri => Uri.parse('$baseUrl/images/generations');

  Map<String, String> get defaultHeaders => profile.buildHeaders(
        apiKey: apiKey,
        extraHeaders: {
          if (settings.organization case final organization?)
            'openai-organization': organization,
          if (settings.project case final project?) 'openai-project': project,
          ...settings.headers,
        },
      );

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    final providerOptions = request.callOptions.providerOptions;
    if (providerOptions != null && providerOptions is! OpenAIImageOptions) {
      throw ArgumentError.value(
        providerOptions,
        'request.callOptions.providerOptions',
        'Expected OpenAIImageOptions for OpenAI-family image models.',
      );
    }

    final options = providerOptions as OpenAIImageOptions?;
    final response = await transport.send(
      TransportRequest(
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
          if (options?.outputFormat case final outputFormat?)
            'output_format': outputFormat.value,
          if (options?.user case final user?) 'user': user,
          if (_shouldIncludeResponseFormat(modelId))
            'response_format': (options?.responseFormat ??
                    OpenAIImageResponseFormat.base64Json)
                .value,
        },
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _decodeResponse(
      response.body,
      requestedResponseFormat: _shouldIncludeResponseFormat(modelId)
          ? (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
          : null,
    );
  }

  ImageGenerationResult _decodeResponse(
    Object? body, {
    required OpenAIImageResponseFormat? requestedResponseFormat,
  }) {
    final json = _decodeJsonObject(body);
    final data = json['data'];
    if (data is! List) {
      throw StateError(
        'Expected an OpenAI image generation response with a data list.',
      );
    }

    final outputFormat = _asString(json['output_format']);
    final revisedPrompts = <String>[];
    final images = <GeneratedImage>[];

    for (var index = 0; index < data.length; index += 1) {
      final item = data[index];
      if (item is! Map) {
        throw StateError(
          'Expected OpenAI image item $index to be a JSON object.',
        );
      }

      final map = Map<String, Object?>.from(item);
      final revisedPrompt = _asString(map['revised_prompt']);
      if (revisedPrompt != null && revisedPrompt.isNotEmpty) {
        revisedPrompts.add(revisedPrompt);
      }

      final b64Json = _asString(map['b64_json']);
      final url = _asString(map['url']);
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
      providerMetadata: ProviderMetadata.forNamespace(
        'openai',
        {
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
      'Expected an OpenAI image generation JSON object but received ${body.runtimeType}.',
    );
  }

  static OpenAIImageModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is OpenAIImageModelSettings) {
      return settings;
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected OpenAIImageModelSettings for OpenAI-family image models.',
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
  ];

  return defaultResponseFormatPrefixes.any(modelId.startsWith);
}

String? _asString(Object? value) {
  return value is String ? value : null;
}

String _mediaTypeForOutputFormat(String? outputFormat) {
  return switch (outputFormat) {
    'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'image/png',
  };
}
