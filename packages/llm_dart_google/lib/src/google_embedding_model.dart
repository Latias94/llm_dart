import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_options.dart';

final class GoogleEmbeddingModel implements EmbeddingModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final GoogleEmbeddingModelSettings settings;

  @override
  final String modelId;

  GoogleEmbeddingModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const GoogleEmbeddingModelSettings(),
  })  : settings = _resolveSettings(settings),
        baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerId => 'google';

  Uri get embedContentUri =>
      Uri.parse('${_normalizedBaseUrl()}/models/$modelId:embedContent');

  Uri get batchEmbedContentsUri => Uri.parse(
        '${_normalizedBaseUrl()}/models/$modelId:batchEmbedContents',
      );

  @override
  Future<EmbedResult> embed(EmbedRequest request) async {
    final providerOptions = request.callOptions.providerOptions;
    if (providerOptions != null && providerOptions is! GoogleEmbedOptions) {
      throw ArgumentError.value(
        providerOptions,
        'request.callOptions.providerOptions',
        'Expected GoogleEmbedOptions for Google embedding models.',
      );
    }

    final options = providerOptions as GoogleEmbedOptions?;
    final isSingle = request.values.length == 1;
    final response = await transport.send(
      TransportRequest(
        uri: isSingle ? embedContentUri : batchEmbedContentsUri,
        method: TransportMethod.post,
        headers: {
          'x-goog-api-key': apiKey,
          'content-type': 'application/json',
          'accept': 'application/json',
          ...settings.headers,
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: isSingle
            ? _buildSingleRequest(
                request.values.single,
                dimensions: request.dimensions,
                options: options,
              )
            : _buildBatchRequest(
                request.values,
                dimensions: request.dimensions,
                options: options,
              ),
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    final json = _decodeJsonObject(response.body);
    return EmbedResult(
      embeddings: isSingle
          ? [
              _decodeSingleEmbedding(json),
            ]
          : _decodeBatchEmbeddings(json),
      usage: _decodeUsage(json['usageMetadata']),
    );
  }

  Map<String, Object?> _buildSingleRequest(
    String value, {
    required int? dimensions,
    required GoogleEmbedOptions? options,
  }) {
    return {
      'content': {
        'parts': [
          {'text': value},
        ],
      },
      if (options?.taskType case final taskType?) 'taskType': taskType,
      if (options?.title case final title?) 'title': title,
      if (dimensions != null) 'outputDimensionality': dimensions,
    };
  }

  Map<String, Object?> _buildBatchRequest(
    List<String> values, {
    required int? dimensions,
    required GoogleEmbedOptions? options,
  }) {
    return {
      'requests': values
          .map(
            (value) => <String, Object?>{
              'model': 'models/$modelId',
              'content': {
                'parts': [
                  {'text': value},
                ],
              },
              if (options?.taskType case final taskType?) 'taskType': taskType,
              if (options?.title case final title?) 'title': title,
              if (dimensions != null) 'outputDimensionality': dimensions,
            },
          )
          .toList(),
    };
  }

  List<double> _decodeSingleEmbedding(Map<String, Object?> json) {
    final embedding = json['embedding'];
    if (embedding is! Map) {
      throw StateError(
        'Expected a Google embedding response with an embedding object.',
      );
    }

    return _decodeEmbeddingValues(
      Map<String, Object?>.from(embedding),
      fieldPath: 'embedding',
    );
  }

  List<List<double>> _decodeBatchEmbeddings(Map<String, Object?> json) {
    final embeddings = json['embeddings'];
    if (embeddings is! List) {
      throw StateError(
        'Expected a Google batch embedding response with an embeddings list.',
      );
    }

    return embeddings.asMap().entries.map((entry) {
      final item = entry.value;
      if (item is! Map) {
        throw StateError(
          'Expected Google batch embedding item ${entry.key} to be a JSON object.',
        );
      }

      final map = Map<String, Object?>.from(item);
      final embedding = map['embedding'];
      if (embedding is! Map) {
        throw StateError(
          'Expected Google batch embedding item ${entry.key} to contain an embedding object.',
        );
      }

      return _decodeEmbeddingValues(
        Map<String, Object?>.from(embedding),
        fieldPath: 'embeddings[${entry.key}].embedding',
      );
    }).toList();
  }

  List<double> _decodeEmbeddingValues(
    Map<String, Object?> embedding, {
    required String fieldPath,
  }) {
    final values = embedding['values'];
    if (values is! List) {
      throw StateError(
        'Expected Google $fieldPath.values to be a numeric list.',
      );
    }

    return List<double>.unmodifiable(
      values.map((value) {
        if (value is! num) {
          throw StateError(
            'Expected Google embedding value in $fieldPath.values to be numeric, got ${value.runtimeType}.',
          );
        }

        return value.toDouble();
      }),
    );
  }

  UsageStats? _decodeUsage(Object? usage) {
    if (usage is! Map) {
      return null;
    }

    final map = Map<String, Object?>.from(usage);
    return UsageStats(
      inputTokens: _asInt(map['promptTokenCount']),
      totalTokens: _asInt(map['totalTokenCount']),
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
      'Expected a Google JSON object response but received ${body.runtimeType}.',
    );
  }

  String _normalizedBaseUrl() {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  static GoogleEmbeddingModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is GoogleEmbeddingModelSettings) {
      return settings;
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected GoogleEmbeddingModelSettings for Google embedding models.',
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
