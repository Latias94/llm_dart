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
  LLMBuilder azure([AzureBuilder Function(AzureBuilder)? configure]) {
    BuiltinProviderRegistry.ensureRegistered();
    provider('azure');
    if (configure != null) {
      configure(AzureBuilder(this));
    }
    return this;
  }

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
  @Deprecated(
    'Prefer the first-party DeepSeek provider (`LLMBuilder.deepseek()` / providerId `deepseek`). '
    'Use `deepseek-openai` only when you must target an OpenAI-compatible endpoint.',
  )
  LLMBuilder deepseekOpenAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'deepseek-openai',
    );
    return provider('deepseek-openai');
  }

  @Deprecated(
    'Prefer the native Google provider (`LLMBuilder.google()` / providerId `google`). '
    'Use `google-openai` only when you must target an OpenAI-compatible endpoint.',
  )
  LLMBuilder googleOpenAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'google-openai',
    );
    return provider('google-openai');
  }

  @Deprecated(
    'Prefer the first-party xAI provider (`LLMBuilder.xai()` / providerId `xai`). '
    'Use `xai-openai` only when you must target an OpenAI-compatible endpoint.',
  )
  LLMBuilder xaiOpenAI() {
    BuiltinProviderRegistry.ensureOpenAICompatibleProviderRegistered(
      'xai-openai',
    );
    return provider('xai-openai');
  }

  @Deprecated(
    'Prefer the first-party Groq provider (`LLMBuilder.groq()` / providerId `groq`). '
    'Use `groq-openai` only when you must target an OpenAI-compatible endpoint.',
  )
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

    final isResponsesAPIEnabled =
        currentConfig.getProviderOption<bool>('openai', 'useResponsesAPI') ??
            false;
    if (!isResponsesAPIEnabled) {
      providerOption('openai', 'useResponsesAPI', true);
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
