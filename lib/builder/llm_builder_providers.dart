import 'llm_builder.dart';

import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_impl;

import '../providers/openai/builder.dart';
import '../providers/anthropic/builder.dart';
import '../providers/google/builder.dart';
import '../providers/google/tts.dart';
import '../providers/ollama/builder.dart';
import '../providers/elevenlabs/builder.dart';
import '../providers/openai/compatible/openrouter/builder.dart';

/// Provider-specific convenience methods for [LLMBuilder].
///
/// These methods are exposed as an extension on [LLMBuilder] to configure
/// built-in providers:
/// - `.openai((openai) => ...)`
/// - `.anthropic((anthropic) => ...)`
/// - `.google((google) => ...)`
/// - `.ollama((ollama) => ...)`
/// - `.elevenlabs((e) => ...)`
/// and OpenAI-compatible providers:
/// - `.deepseekOpenAI()`, `.googleOpenAI()`, `.xaiOpenAI()`, `.groqOpenAI()`,
///   `.phindOpenAI()`, `.openRouter((openrouter) => ...)`
///
/// This keeps the core [LLMBuilder] neutral while concentrating
/// provider-specific semantics in this extension.
extension LLMBuilderProviderShortcuts on LLMBuilder {
  /// Configure the OpenAI provider.
  ///
  /// Example:
  /// ```dart
  /// final model = await ai()
  ///   .openai((openai) => openai.verbosity(Verbosity.high))
  ///   .apiKey(apiKey)
  ///   .model('gpt-4o')
  ///   .buildLanguageModel();
  /// ```
  LLMBuilder openai([OpenAIBuilder Function(OpenAIBuilder)? configure]) {
    provider('openai');
    if (configure != null) {
      final openaiBuilder = OpenAIBuilder(this);
      configure(openaiBuilder);
    }
    return this;
  }

  /// Configure the Anthropic provider.
  LLMBuilder anthropic(
      [AnthropicBuilder Function(AnthropicBuilder)? configure]) {
    provider('anthropic');
    if (configure != null) {
      final anthropicBuilder = AnthropicBuilder(this);
      configure(anthropicBuilder);
    }
    return this;
  }

  /// Configure the Google (Gemini) provider.
  LLMBuilder google([GoogleLLMBuilder Function(GoogleLLMBuilder)? configure]) {
    provider('google');
    if (configure != null) {
      final googleBuilder = GoogleLLMBuilder(this);
      configure(googleBuilder);
    }
    return this;
  }

  /// Configure the DeepSeek provider.
  LLMBuilder deepseek() => provider('deepseek');

  /// Configure the Ollama provider.
  LLMBuilder ollama([OllamaBuilder Function(OllamaBuilder)? configure]) {
    provider('ollama');
    if (configure != null) {
      final ollamaBuilder = OllamaBuilder(this);
      configure(ollamaBuilder);
    }
    return this;
  }

  /// Configure the xAI provider.
  LLMBuilder xai() => provider('xai');

  /// Configure the Phind provider.
  LLMBuilder phind() => provider('phind');

  /// Configure the Groq provider.
  LLMBuilder groq() => provider('groq');

  /// Configure the ElevenLabs provider.
  LLMBuilder elevenlabs(
      [ElevenLabsBuilder Function(ElevenLabsBuilder)? configure]) {
    provider('elevenlabs');
    if (configure != null) {
      final elevenLabsBuilder = ElevenLabsBuilder(this);
      configure(elevenLabsBuilder);
    }
    return this;
  }

  // ===== OpenAI-compatible providers via OpenAI REST shape =====

  /// Configure DeepSeek via its OpenAI-compatible endpoint.
  LLMBuilder deepseekOpenAI() => provider('deepseek-openai');

  /// Configure Google Gemini via its OpenAI-compatible endpoint.
  LLMBuilder googleOpenAI() => provider('google-openai');

  /// Configure xAI via its OpenAI-compatible endpoint.
  LLMBuilder xaiOpenAI() => provider('xai-openai');

  /// Configure Groq via its OpenAI-compatible endpoint.
  LLMBuilder groqOpenAI() => provider('groq-openai');

  /// Configure Phind via its OpenAI-compatible endpoint.
  LLMBuilder phindOpenAI() => provider('phind-openai');

  /// Configure OpenRouter via the OpenAI-compatible layer.
  LLMBuilder openRouter(
      [OpenRouterBuilder Function(OpenRouterBuilder)? configure]) {
    provider('openrouter');
    if (configure != null) {
      final openRouterBuilder = OpenRouterBuilder(this);
      configure(openRouterBuilder);
    }
    return this;
  }

  /// Configure GitHub Copilot as an OpenAI-compatible provider.
  LLMBuilder githubCopilot() => provider('github-copilot');

  /// Configure Together AI as an OpenAI-compatible provider.
  LLMBuilder togetherAI() => provider('together-ai');

  // ===== Advanced build helpers =====

  /// Builds an OpenAI provider with Responses API enabled.
  ///
  /// This is a convenience method equivalent to:
  /// - `.openai((o) => o.useResponsesAPI(...))`
  /// - then constructing `openai_impl.OpenAIProvider` and ensuring
  ///   that `responses` is initialized.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai((openai) => openai
  ///         .webSearchTool()
  ///         .fileSearchTool(vectorStoreIds: ['vs_123']))
  ///     .apiKey(apiKey)
  ///     .model('gpt-4o')
  ///     .buildOpenAIResponses();
  /// ```
  Future<openai_impl.OpenAIProvider> buildOpenAIResponses() {
    return OpenAIBuilder(this).buildOpenAIResponses();
  }

  /// Builds a Google provider with TTS capability.
  ///
  /// This is a convenience method that constructs a Google provider
  /// implementing [GoogleTTSCapability]:
  /// ```dart
  /// final ttsProvider = await ai()
  ///     .google((google) => google.ttsModel('gemini-2.5-flash-preview-tts'))
  ///     .apiKey(apiKey)
  ///     .buildGoogleTTS();
  /// ```
  Future<GoogleTTSCapability> buildGoogleTTS() {
    return GoogleLLMBuilder(this).buildGoogleTTS();
  }
}
