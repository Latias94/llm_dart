import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_binary_resolver.dart';

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
