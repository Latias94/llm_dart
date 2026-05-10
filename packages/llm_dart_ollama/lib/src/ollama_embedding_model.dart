import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_model_describer.dart';
import 'ollama_options.dart';

/// Package-owned modern Ollama embedding model surface.
final class OllamaEmbeddingModel
    implements EmbeddingModel, CapabilityDescribedModel {
  final String? apiKey;
  final String baseUrl;
  final TransportClient transport;
  final OllamaEmbeddingModelSettings settings;

  @override
  final String modelId;

  OllamaEmbeddingModel({
    required this.modelId,
    required this.transport,
    String? apiKey,
    String? baseUrl,
    ProviderModelOptions settings = const OllamaEmbeddingModelSettings(),
  })  : apiKey = normalizeOllamaApiKey(apiKey),
        baseUrl = normalizeOllamaBaseUrl(baseUrl),
        settings = _resolveSettings(settings);

  @override
  String get providerId => 'ollama';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOllamaEmbeddingModel(modelId);
  }

  Uri get embedUri => resolveOllamaUri(baseUrl, '/api/embed');

  Map<String, String> get defaultHeaders => buildOllamaHeaders(
        apiKey: apiKey,
        contentType: 'application/json',
        headers: settings.headers,
      );

  @override
  Future<EmbedResult> embed(EmbedRequest request) async {
    if (request.values.isEmpty) {
      throw ArgumentError.value(
        request.values,
        'request.values',
        'Ollama embedding requests require at least one value.',
      );
    }

    if (request.dimensions != null) {
      throw ArgumentError.value(
        request.dimensions,
        'request.dimensions',
        'Ollama embeddings do not support overriding output dimensions.',
      );
    }

    if (request.callOptions.providerOptions != null) {
      throw ArgumentError.value(
        request.callOptions.providerOptions,
        'request.callOptions.providerOptions',
        'Ollama embedding models do not define provider invocation options yet.',
      );
    }

    final response = await transport.send(
      TransportRequest(
        uri: embedUri,
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: {
          'model': modelId,
          'input': request.values,
        },
        timeout: request.callOptions.timeout,
        maxRetries: request.callOptions.maxRetries,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    final json = decodeOllamaJsonObject(
      response.body,
      responseName: 'embedding response',
    );
    return EmbedResult(
      embeddings: _decodeEmbeddings(json),
      providerMetadata: ProviderMetadata.forNamespace(
        'ollama',
        {
          if (json['total_duration'] != null)
            'totalDurationNanos': json['total_duration'],
          if (json['load_duration'] != null)
            'loadDurationNanos': json['load_duration'],
          if (json['prompt_eval_count'] != null)
            'promptEvalCount': json['prompt_eval_count'],
        },
      ),
    );
  }

  static OllamaEmbeddingModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    return resolveProviderModelOptions<OllamaEmbeddingModelSettings>(
      settings,
      parameterName: 'settings',
      expectedTypeName: 'OllamaEmbeddingModelSettings',
      usageContext: 'Ollama embedding models',
    );
  }
}

List<List<double>> _decodeEmbeddings(Map<String, Object?> json) {
  final embeddings = json['embeddings'];
  if (embeddings is! List) {
    throw StateError(
      'Expected Ollama embedding response to contain an embeddings list.',
    );
  }

  return embeddings.asMap().entries.map((entry) {
    final value = entry.value;
    if (value is! List) {
      throw StateError(
        'Expected Ollama embedding item ${entry.key} to be a numeric list.',
      );
    }

    return List<double>.unmodifiable(
      value.map((item) {
        if (item is! num) {
          throw StateError(
            'Expected Ollama embedding value ${entry.key} to be numeric, got ${item.runtimeType}.',
          );
        }

        return item.toDouble();
      }),
    );
  }).toList();
}
