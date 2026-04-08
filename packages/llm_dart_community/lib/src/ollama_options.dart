import 'package:llm_dart_core/llm_dart_core.dart';

const ollamaDefaultBaseUrl = 'http://localhost:11434';

/// Provider-owned model settings for package-owned Ollama language models.
final class OllamaChatModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;

  const OllamaChatModelSettings({
    this.headers = const {},
  });
}

/// Provider-owned model settings for package-owned Ollama embedding models.
final class OllamaEmbeddingModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;

  const OllamaEmbeddingModelSettings({
    this.headers = const {},
  });
}

/// Provider-owned invocation options for Ollama text generation requests.
final class OllamaGenerateTextOptions implements ProviderInvocationOptions {
  final int? numCtx;
  final int? numGpu;
  final int? numThread;
  final int? numBatch;
  final bool? numa;
  final String? keepAlive;
  final bool? raw;
  final bool? reasoning;

  const OllamaGenerateTextOptions({
    this.numCtx,
    this.numGpu,
    this.numThread,
    this.numBatch,
    this.numa,
    this.keepAlive,
    this.raw,
    this.reasoning,
  });
}
