import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_options.dart';

final class OpenAIEmbeddingModel implements EmbeddingModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIEmbeddingModelSettings settings;

  @override
  final String modelId;

  OpenAIEmbeddingModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAIEmbeddingModelSettings(),
  })  : settings = _resolveSettings(settings),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  Uri get embeddingsUri => Uri.parse('$baseUrl/embeddings');

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
  Future<EmbedResult> embed(EmbedRequest request) async {
    final providerOptions = request.callOptions.providerOptions;
    if (providerOptions != null && providerOptions is! OpenAIEmbedOptions) {
      throw ArgumentError.value(
        providerOptions,
        'request.callOptions.providerOptions',
        'Expected OpenAIEmbedOptions for OpenAI-family embedding models.',
      );
    }

    final options = providerOptions as OpenAIEmbedOptions?;
    final response = await transport.send(
      TransportRequest(
        uri: embeddingsUri,
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          'content-type': 'application/json',
          'accept': 'application/json',
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: {
          'model': modelId,
          'input': request.values,
          if (request.dimensions != null) 'dimensions': request.dimensions,
          if (options?.encodingFormat case final encodingFormat?)
            'encoding_format': encodingFormat,
        },
        timeout: request.callOptions.timeout,
        responseType: TransportResponseType.json,
      ),
    );

    return _decodeResponse(response.body);
  }

  EmbedResult _decodeResponse(Object? body) {
    final json = _decodeJsonObject(body);
    final data = json['data'];
    if (data is! List) {
      throw StateError(
        'Expected an OpenAI embeddings response with a data list.',
      );
    }

    final indexedEmbeddings = <({int index, List<double> embedding})>[];
    for (var index = 0; index < data.length; index += 1) {
      final item = data[index];
      if (item is! Map) {
        throw StateError(
          'Expected OpenAI embedding item $index to be a JSON object.',
        );
      }

      final map = Map<String, Object?>.from(item);
      final embedding = map['embedding'];
      if (embedding is! List) {
        throw StateError(
          'Expected OpenAI embedding item $index to contain an embedding list.',
        );
      }

      indexedEmbeddings.add(
        (
          index: _asInt(map['index']) ?? index,
          embedding: List<double>.unmodifiable(
            embedding.map((value) {
              if (value is! num) {
                throw StateError(
                  'Expected OpenAI embedding value to be numeric, got '
                  '${value.runtimeType}.',
                );
              }

              return value.toDouble();
            }),
          ),
        ),
      );
    }

    indexedEmbeddings.sort((left, right) => left.index.compareTo(right.index));

    return EmbedResult(
      embeddings: indexedEmbeddings.map((entry) => entry.embedding).toList(),
      usage: _decodeUsage(json['usage']),
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
      'Expected an OpenAI JSON object response but received ${body.runtimeType}.',
    );
  }

  UsageStats? _decodeUsage(Object? usage) {
    if (usage is! Map) {
      return null;
    }

    final map = Map<String, Object?>.from(usage);
    return UsageStats(
      inputTokens: _asInt(map['prompt_tokens']),
      totalTokens: _asInt(map['total_tokens']),
    );
  }

  static OpenAIEmbeddingModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is OpenAIEmbeddingModelSettings) {
      return settings;
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected OpenAIEmbeddingModelSettings for OpenAI-family embedding models.',
    );
  }

  int? _asInt(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      _ => null,
    };
  }
}
