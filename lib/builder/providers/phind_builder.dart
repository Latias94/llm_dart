import '../llm_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Phind-specific LLM builder with provider-specific configuration methods.
///
/// This builder lets you configure Phind-specific behavior for coding and
/// reasoning tasks on top of the generic [LLMBuilder] configuration.
///
/// Use this for Phind-specific parameters only. For common parameters like
/// [LLMBuilder.apiKey], [LLMBuilder.model], [LLMBuilder.temperature], etc.,
/// continue using the base [LLMBuilder] methods.
class PhindBuilder {
  final LLMBuilder _baseBuilder;

  PhindBuilder(this._baseBuilder);

  /// Convenience helper to configure a coding-focused system prompt.
  ///
  /// This sets a Phind-optimized system prompt via [LLMBuilder.systemPrompt]
  /// for general coding tasks.
  PhindBuilder forCodingAssistant() {
    _baseBuilder.systemPrompt(
      'You are Phind-70B, an expert coding assistant. '
      'Provide clear, well-structured answers with code examples where helpful.',
    );
    return this;
  }

  /// Convenience helper to configure a code generation system prompt.
  ///
  /// This sets a deterministic, code-focused system prompt and leaves
  /// sampling configuration (like temperature) to the base builder.
  PhindBuilder forCodeGeneration() {
    _baseBuilder.systemPrompt(
      'You are a code generation assistant. '
      'Produce concise, correct code with minimal commentary.',
    );
    return this;
  }

  /// Convenience helper to configure a code explanation system prompt.
  ///
  /// This is tuned for explaining code and concepts with examples.
  PhindBuilder forCodeExplanation() {
    _baseBuilder.systemPrompt(
      'You are a coding tutor. '
      'Explain code concepts clearly and provide illustrative examples.',
    );
    return this;
  }

  // ========== Build methods ==========

  /// Builds and returns a configured Phind chat provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }
}
