import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_embedding_model_request.dart';
import 'ollama_embedding_model_response.dart';
import 'ollama_embedding_model_transport.dart';
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
        settings = resolveOllamaEmbeddingModelSettings(settings);

  @override
  String get providerId => 'ollama';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOllamaEmbeddingModel(modelId);
  }

  @override
  int? get maxEmbeddingsPerCall => null;

  @override
  bool get supportsParallelCalls => false;

  Uri get embedUri => resolveOllamaEmbeddingRouteUri(baseUrl: baseUrl);

  Map<String, String> get defaultHeaders => buildOllamaEmbeddingDefaultHeaders(
        apiKey: apiKey,
        settings: settings,
      );

  @override
  Future<EmbedResult> doEmbed(EmbedRequest request) async {
    validateOllamaEmbeddingRequest(request);
    final body = buildOllamaEmbeddingRequestBody(
      modelId: modelId,
      request: request,
    );
    final response = await transport.send(
      buildOllamaEmbeddingTransportRequest(
        baseUrl: baseUrl,
        request: request,
        body: body,
        defaultHeaders: defaultHeaders,
      ),
    );

    return decodeOllamaEmbeddingResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
    );
  }
}
