import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_embedding_model.dart';
import 'ollama_language_model.dart';
import 'ollama_model_catalog.dart';
import 'ollama_options.dart';

/// Package-owned Ollama namespace for modern community provider surfaces.
final class Ollama {
  static const String defaultBaseUrl = ollamaDefaultBaseUrl;

  final String baseUrl;
  final String? apiKey;
  final TransportClient transport;

  Ollama({
    this.apiKey,
    TransportClient? transport,
    String? baseUrl,
  })  : baseUrl = normalizeOllamaBaseUrl(baseUrl),
        transport = transport ?? DioTransportClient();

  OllamaEmbeddingModel embeddingModel(
    String modelId, {
    OllamaEmbeddingModelSettings settings =
        const OllamaEmbeddingModelSettings(),
  }) {
    return OllamaEmbeddingModel(
      modelId: modelId,
      apiKey: apiKey,
      baseUrl: baseUrl,
      transport: transport,
      settings: settings,
    );
  }

  OllamaLanguageModel chatModel(
    String modelId, {
    OllamaChatModelSettings settings = const OllamaChatModelSettings(),
  }) {
    return OllamaLanguageModel(
      modelId: modelId,
      apiKey: apiKey,
      baseUrl: baseUrl,
      transport: transport,
      settings: settings,
    );
  }

  OllamaModelCatalogClient catalog({
    OllamaCatalogSettings settings = const OllamaCatalogSettings(),
  }) {
    return OllamaModelCatalogClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
      transport: transport,
      settings: settings,
    );
  }
}
