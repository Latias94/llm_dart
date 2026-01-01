import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Ollama-specific LLM builder with provider-specific configuration methods.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class OllamaBuilder {
  final LLMBuilder _baseBuilder;

  OllamaBuilder(this._baseBuilder);

  OllamaBuilder numCtx(int value) {
    _baseBuilder.option('numCtx', value);
    return this;
  }

  OllamaBuilder numGpu(int value) {
    _baseBuilder.option('numGpu', value);
    return this;
  }

  OllamaBuilder numThread(int value) {
    _baseBuilder.option('numThread', value);
    return this;
  }

  OllamaBuilder numa(bool enabled) {
    _baseBuilder.option('numa', enabled);
    return this;
  }

  OllamaBuilder numBatch(int value) {
    _baseBuilder.option('numBatch', value);
    return this;
  }

  OllamaBuilder keepAlive(String value) {
    _baseBuilder.option('keepAlive', value);
    return this;
  }

  OllamaBuilder raw(bool enabled) {
    _baseBuilder.option('raw', enabled);
    return this;
  }

  OllamaBuilder reasoning(bool enabled) {
    _baseBuilder.option('reasoning', enabled);
    return this;
  }

  Future<ChatCapability> build() async => _baseBuilder.build();
}
