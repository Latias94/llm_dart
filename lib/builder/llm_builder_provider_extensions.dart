import '../providers/anthropic/builder.dart';
import '../providers/elevenlabs/builder.dart';
import '../providers/google/builder.dart';
import '../providers/ollama/builder.dart';
import '../providers/openai/builder.dart';
import '../providers/openai/compatible/openrouter/builder.dart';
import 'llm_builder.dart';

/// Provider-specific convenience methods layered on top of [LLMBuilder].
extension LLMBuilderProviderExtensions on LLMBuilder {
  /// Selects the OpenAI provider and applies optional OpenAI-specific config.
  LLMBuilder openai([OpenAIBuilder Function(OpenAIBuilder)? configure]) {
    provider('openai');
    if (configure != null) {
      configure(OpenAIBuilder(this));
    }
    return this;
  }

  /// Selects the Anthropic provider and applies optional Anthropic config.
  LLMBuilder anthropic(
      [AnthropicBuilder Function(AnthropicBuilder)? configure]) {
    provider('anthropic');
    if (configure != null) {
      configure(AnthropicBuilder(this));
    }
    return this;
  }

  /// Selects the Google provider and applies optional Google-specific config.
  LLMBuilder google([GoogleLLMBuilder Function(GoogleLLMBuilder)? configure]) {
    provider('google');
    if (configure != null) {
      configure(GoogleLLMBuilder(this));
    }
    return this;
  }

  /// Selects the Ollama provider and applies optional Ollama-specific config.
  LLMBuilder ollama([OllamaBuilder Function(OllamaBuilder)? configure]) {
    provider('ollama');
    if (configure != null) {
      configure(OllamaBuilder(this));
    }
    return this;
  }

  /// Selects the ElevenLabs provider and applies optional ElevenLabs config.
  LLMBuilder elevenlabs(
      [ElevenLabsBuilder Function(ElevenLabsBuilder)? configure]) {
    provider('elevenlabs');
    if (configure != null) {
      configure(ElevenLabsBuilder(this));
    }
    return this;
  }

  /// Selects the OpenRouter provider and applies optional OpenRouter config.
  LLMBuilder openRouter(
      [OpenRouterBuilder Function(OpenRouterBuilder)? configure]) {
    provider('openrouter');
    if (configure != null) {
      configure(OpenRouterBuilder(this));
    }
    return this;
  }
}
