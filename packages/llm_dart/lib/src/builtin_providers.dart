import 'package:llm_dart_core/llm_dart_core.dart';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart'
    show AnthropicProviderFactory;
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart'
    show DeepSeekProviderFactory;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart'
    show ElevenLabsProviderFactory;
import 'package:llm_dart_google/llm_dart_google.dart'
    show GoogleProviderFactory;
import 'package:llm_dart_groq/llm_dart_groq.dart' show GroqProviderFactory;
import 'package:llm_dart_ollama/llm_dart_ollama.dart'
    show OllamaProviderFactory;
import 'package:llm_dart_openai/llm_dart_openai.dart'
    show OpenAIProviderFactory;
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart'
    show OpenAICompatibleProviderRegistrar;
import 'package:llm_dart_phind/llm_dart_phind.dart' show PhindProviderFactory;
import 'package:llm_dart_xai/llm_dart_xai.dart' show XAIProviderFactory;

bool _builtinsRegistered = false;

/// Register all built-in provider factories with the global registry.
///
/// The root `llm_dart` package is the "full bundle" and can lazily register
/// all built-in providers on first use. Advanced users who prefer explicit
/// control can depend on `llm_dart_core` + provider subpackages and call the
/// provider registrars directly (e.g. `registerOpenAIProvider()`).
void registerBuiltinProviders() {
  if (_builtinsRegistered) return;
  _builtinsRegistered = true;

  void safeRegister(LLMProviderFactory factory) {
    try {
      ProviderFactoryRegistry.registerOrReplace(factory);
    } catch (_) {
      // Ignore registration errors for built-in providers.
    }
  }

  safeRegister(OpenAIProviderFactory());
  safeRegister(AnthropicProviderFactory());
  safeRegister(DeepSeekProviderFactory());
  safeRegister(OllamaProviderFactory());
  safeRegister(GoogleProviderFactory());
  safeRegister(XAIProviderFactory());
  safeRegister(PhindProviderFactory());
  safeRegister(GroqProviderFactory());
  safeRegister(ElevenLabsProviderFactory());

  // Register OpenAI-compatible providers (OpenRouter, Google via OpenAI layer, etc.).
  try {
    OpenAICompatibleProviderRegistrar.registerAll();
  } catch (_) {
    // Ignore errors when OpenAI-compatible providers are not available.
  }
}
