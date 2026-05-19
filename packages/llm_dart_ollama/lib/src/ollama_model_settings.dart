import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_binary_resolver.dart';

/// Provider-owned model settings for package-owned Ollama language models.
final class OllamaChatModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final OllamaBinaryResolver? binaryResolver;

  const OllamaChatModelSettings({
    this.headers = const {},
    this.binaryResolver,
  });
}

/// Provider-owned model settings for package-owned Ollama embedding models.
final class OllamaEmbeddingModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;

  const OllamaEmbeddingModelSettings({
    this.headers = const {},
  });
}
