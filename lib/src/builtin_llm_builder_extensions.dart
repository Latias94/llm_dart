import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart' show GoogleTTSCapability;
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';

import '../builtins/builtin_provider_registry.dart';
import 'anthropic_builder.dart';
import 'elevenlabs_builder.dart';
import 'google_llm_builder.dart';
import 'ollama_builder.dart';
import 'openai_builder.dart';
import 'openrouter_builder.dart';

/// Convenience methods for built-in providers.
extension BuiltinProviderBuilders on LLMBuilder {
  LLMBuilder openai([OpenAIBuilder Function(OpenAIBuilder)? configure]) {
    BuiltinProviderRegistry.ensureRegistered();
    provider('openai');
    if (configure != null) {
      configure(OpenAIBuilder(this));
    }
    return this;
  }

  LLMBuilder anthropic(
      [AnthropicBuilder Function(AnthropicBuilder)? configure]) {
    BuiltinProviderRegistry.ensureRegistered();
    provider('anthropic');
    if (configure != null) {
      configure(AnthropicBuilder(this));
    }
    return this;
  }

  LLMBuilder google([GoogleLLMBuilder Function(GoogleLLMBuilder)? configure]) {
    BuiltinProviderRegistry.ensureRegistered();
    provider('google');
    if (configure != null) {
      configure(GoogleLLMBuilder(this));
    }
    return this;
  }

  LLMBuilder deepseek() {
    BuiltinProviderRegistry.ensureRegistered();
    return provider('deepseek');
  }

  LLMBuilder ollama([OllamaBuilder Function(OllamaBuilder)? configure]) {
    BuiltinProviderRegistry.ensureRegistered();
    provider('ollama');
    if (configure != null) {
      configure(OllamaBuilder(this));
    }
    return this;
  }

  LLMBuilder xai() {
    BuiltinProviderRegistry.ensureRegistered();
    return provider('xai');
  }

  LLMBuilder groq() {
    BuiltinProviderRegistry.ensureRegistered();
    return provider('groq');
  }

  LLMBuilder minimax() {
    BuiltinProviderRegistry.ensureRegistered();
    return provider('minimax');
  }

  LLMBuilder elevenlabs(
      [ElevenLabsBuilder Function(ElevenLabsBuilder)? configure]) {
    BuiltinProviderRegistry.ensureRegistered();
    provider('elevenlabs');
    if (configure != null) {
      configure(ElevenLabsBuilder(this));
    }
    return this;
  }

  // OpenAI-compatible providers
  LLMBuilder deepseekOpenAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'deepseek-openai',
    );
    return provider('deepseek-openai');
  }

  LLMBuilder googleOpenAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'google-openai',
    );
    return provider('google-openai');
  }

  LLMBuilder xaiOpenAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'xai-openai',
    );
    return provider('xai-openai');
  }

  LLMBuilder groqOpenAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'groq-openai',
    );
    return provider('groq-openai');
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

  LLMBuilder githubCopilot() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'github-copilot',
    );
    return provider('github-copilot');
  }

  LLMBuilder togetherAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'together-ai',
    );
    return provider('together-ai');
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

    final isResponsesAPIEnabled =
        currentConfig.getProviderOption<bool>('openai', 'useResponsesAPI') ??
            false;
    if (!isResponsesAPIEnabled) {
      providerOption('openai', 'useResponsesAPI', true);
    }

    final provider = await build();
    final openaiProvider = provider as OpenAIProvider;

    if (openaiProvider.responses == null) {
      throw StateError('OpenAI Responses API not properly initialized. '
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
