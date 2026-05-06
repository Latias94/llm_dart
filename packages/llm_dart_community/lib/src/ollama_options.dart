import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

const ollamaDefaultBaseUrl = 'http://localhost:11434';

typedef OllamaBinaryResolver = FutureOr<List<int>?> Function(
  Uri uri, {
  required String mediaType,
  String? filename,
});

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
  final OllamaBinaryResolver? binaryResolver;

  const OllamaGenerateTextOptions({
    this.numCtx,
    this.numGpu,
    this.numThread,
    this.numBatch,
    this.numa,
    this.keepAlive,
    this.raw,
    this.reasoning,
    this.binaryResolver,
  });
}
