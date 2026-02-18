import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart' show GoogleTTSCapability;
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';

import '../builtins/builtin_provider_registry.dart';
import 'anthropic_builder.dart';
import 'azure_builder.dart';
import 'elevenlabs_builder.dart';
import 'google_llm_builder.dart';
import 'ollama_builder.dart';
import 'openai_builder.dart';
import 'openai_compatible_builder.dart';
import 'openrouter_builder.dart';

/// Convenience methods for built-in providers.
extension BuiltinProviderBuilders on LLMBuilder {
  /// Select a provider id and ensure it is registered in the umbrella package.
  ///
  /// This is a dynamic alternative to the typed convenience methods (e.g.
  /// `.openai()`, `.anthropic()`) and is useful when provider ids are driven by
  /// configuration.
  ///
  /// Note: this only registers providers that ship with the umbrella package
  /// (and OpenAI-compatible presets supported by `llm_dart_openai_compatible`).
  LLMBuilder builtin(String providerId) {
    BuiltinProviderRegistry.ensureProviderRegistered(providerId);
    return provider(providerId);
  }

  LLMBuilder azure([AzureBuilder Function(AzureBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('azure');
    provider('azure');
    if (configure != null) {
      configure(AzureBuilder(this));
    }
    return this;
  }

  LLMBuilder azureChat([AzureBuilder Function(AzureBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('azure.chat');
    provider('azure.chat');
    if (configure != null) {
      configure(AzureBuilder(this));
    }
    return this;
  }

  LLMBuilder openai([OpenAIBuilder Function(OpenAIBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('openai');
    provider('openai');
    if (configure != null) {
      configure(OpenAIBuilder(this));
    }
    return this;
  }

  LLMBuilder openaiChat([OpenAIBuilder Function(OpenAIBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('openai.chat');
    provider('openai.chat');
    if (configure != null) {
      configure(OpenAIBuilder(this));
    }
    return this;
  }

  LLMBuilder anthropic(
      [AnthropicBuilder Function(AnthropicBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('anthropic');
    provider('anthropic');
    if (configure != null) {
      configure(AnthropicBuilder(this));
    }
    return this;
  }

  LLMBuilder google([GoogleLLMBuilder Function(GoogleLLMBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('google');
    provider('google');
    if (configure != null) {
      configure(GoogleLLMBuilder(this));
    }
    return this;
  }

  LLMBuilder deepseek() {
    BuiltinProviderRegistry.ensureProviderRegistered('deepseek');
    return provider('deepseek');
  }

  LLMBuilder ollama([OllamaBuilder Function(OllamaBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('ollama');
    provider('ollama');
    if (configure != null) {
      configure(OllamaBuilder(this));
    }
    return this;
  }

  LLMBuilder xai() {
    BuiltinProviderRegistry.ensureProviderRegistered('xai');
    return provider('xai');
  }

  LLMBuilder groq() {
    BuiltinProviderRegistry.ensureProviderRegistered('groq');
    return provider('groq');
  }

  LLMBuilder minimax() {
    BuiltinProviderRegistry.ensureProviderRegistered('minimax');
    return provider('minimax');
  }

  LLMBuilder elevenlabs(
      [ElevenLabsBuilder Function(ElevenLabsBuilder)? configure]) {
    BuiltinProviderRegistry.ensureProviderRegistered('elevenlabs');
    provider('elevenlabs');
    if (configure != null) {
      configure(ElevenLabsBuilder(this));
    }
    return this;
  }

  /// Select an OpenAI-compatible preset provider id (opt-in).
  ///
  /// This is intentionally generic to avoid growing the umbrella surface with
  /// one method per preset.
  ///
  /// Example:
  ///
  /// ```dart
  /// final model = await LLMBuilder()
  ///   .openaiCompatible('deepseek-openai')
  ///   .apiKey('...')
  ///   .model('deepseek-chat')
  ///   .build();
  /// ```
  LLMBuilder openaiCompatible(
    String providerId, [
    OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure,
  ]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
        providerId);
    provider(providerId);
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, providerId));
    }
    return this;
  }

  LLMBuilder openRouter(
      [OpenRouterBuilder Function(OpenRouterBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'openrouter',
    );
    provider('openrouter');
    if (configure != null) {
      configure(OpenRouterBuilder(this));
    }
    return this;
  }

  LLMBuilder githubCopilot(
      [OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'github-copilot',
    );
    provider('github-copilot');
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, 'github-copilot'));
    }
    return this;
  }

  LLMBuilder togetherAI(
      [OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'together-ai',
    );
    provider('together-ai');
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, 'together-ai'));
    }
    return this;
  }

  LLMBuilder deepinfraOpenAI(
      [OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'deepinfra-openai',
    );
    provider('deepinfra-openai');
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, 'deepinfra-openai'));
    }
    return this;
  }

  LLMBuilder fireworksOpenAI(
      [OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'fireworks-openai',
    );
    provider('fireworks-openai');
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, 'fireworks-openai'));
    }
    return this;
  }

  LLMBuilder cerebrasOpenAI(
      [OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'cerebras-openai',
    );
    provider('cerebras-openai');
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, 'cerebras-openai'));
    }
    return this;
  }

  LLMBuilder vercelV0(
      [OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'vercel-v0',
    );
    provider('vercel-v0');
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, 'vercel-v0'));
    }
    return this;
  }

  LLMBuilder basetenOpenAI(
      [OpenAICompatibleBuilder Function(OpenAICompatibleBuilder)? configure]) {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'baseten-openai',
    );
    provider('baseten-openai');
    if (configure != null) {
      configure(OpenAICompatibleBuilder(this, 'baseten-openai'));
    }
    return this;
  }
}

/// Provider-specific convenience build methods that require concrete provider types.
extension BuiltinProviderBuildHelpers on LLMBuilder {
  Future<OpenAIProvider> buildOpenAIResponses() async {
    if (providerId != 'openai') {
      throw UnsupportedCapabilityError(
        'buildOpenAIResponses() can only be used with OpenAI provider. '
        'Current provider: $providerId. Use .openai() first.',
      );
    }

    final provider = await build();
    final openaiProvider = provider as OpenAIProvider;

    if (!openaiProvider.supports(LLMCapability.openaiResponses)) {
      throw StateError('OpenAI Responses API not enabled. '
          'This should not happen when using buildOpenAIResponses().');
    }

    return openaiProvider;
  }

  Future<GoogleTTSCapability> buildGoogleTTS() async {
    if (providerId != 'google') {
      throw UnsupportedCapabilityError(
        'buildGoogleTTS() can only be used with Google provider. '
        'Current provider: $providerId. Use .google() first.',
      );
    }

    if (currentConfig.model.isEmpty || !currentConfig.model.contains('tts')) {
      model('gemini-2.5-flash-preview-tts');
    }

    final provider = await build();
    if (provider is! GoogleTTSCapability) {
      throw UnsupportedCapabilityError(
        'Google provider does not support TTS capabilities. '
        'Supported models: gemini-2.5-flash-preview-tts',
      );
    }
    return provider as GoogleTTSCapability;
  }
}
