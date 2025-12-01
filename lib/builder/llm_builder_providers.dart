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
/// 这些方法以 extension 形式挂在 [LLMBuilder] 上，用于配置内置 provider：
/// - `.openai((openai) => ...)`
/// - `.anthropic((anthropic) => ...)`
/// - `.google((google) => ...)`
/// - `.ollama((ollama) => ...)`
/// - `.elevenlabs((e) => ...)`
/// 以及 OpenAI 兼容 provider：
/// - `.deepseekOpenAI()`, `.googleOpenAI()`, `.xaiOpenAI()`, `.groqOpenAI()`,
///   `.phindOpenAI()`, `.openRouter((openrouter) => ...)`
///
/// 这样可以让核心 [LLMBuilder] 保持中立，而 provider 相关语义集中在扩展中。
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
  /// 这是一个便捷方法，等价于：
  /// - `.openai((o) => o.useResponsesAPI(...))`
  /// - 然后构建 `openai_impl.OpenAIProvider` 并确保 `responses` 已正确初始化。
  ///
  /// 示例：
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
  /// 这是一个便捷方法，会构造一个实现了 [GoogleTTSCapability] 的 Google provider：
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
