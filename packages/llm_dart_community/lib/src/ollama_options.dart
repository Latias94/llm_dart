import 'package:llm_dart_core/llm_dart_core.dart';

const ollamaDefaultBaseUrl = 'http://localhost:11434';

/// Provider-owned model settings for package-owned Ollama embedding models.
final class OllamaEmbeddingModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;

  const OllamaEmbeddingModelSettings({
    this.headers = const {},
  });
}
