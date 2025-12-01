library;

/// Backwards-compatible shim for provider registry types.
///
/// The canonical definitions of [LLMProviderFactory], [LLMProviderRegistry],
/// and [ProviderInfo] now live in the `llm_dart_core` package so they can be
/// used by provider subpackages without depending on the root `llm_dart`
/// package.
export 'package:llm_dart_core/llm_dart_core.dart'
    show LLMProviderFactory, LLMProviderRegistry, ProviderInfo;

import 'package:llm_dart_core/llm_dart_core.dart';

import '../providers/factories/openai_factory.dart';
import '../providers/factories/anthropic_factory.dart';
import '../providers/factories/deepseek_factory.dart';
import '../providers/factories/ollama_factory.dart';
import '../providers/factories/google_factory.dart';
import '../providers/factories/xai_factory.dart';
import '../providers/factories/phind_factory.dart';
import '../providers/factories/groq_factory.dart';
import '../providers/factories/elevenlabs_factory.dart';
import '../providers/factories/openai_compatible_factory.dart';

bool _builtinsRegistered = false;

/// Register all built-in provider factories with the global registry.
///
/// This helper mirrors the previous behavior where built-in providers were
/// automatically registered on first use. Callers that prefer explicit
/// control can skip this helper and register only the providers they need.
void registerBuiltinProviders() {
  if (_builtinsRegistered) return;
  _builtinsRegistered = true;

  // Register concrete provider factories. Failures are intentionally ignored
  // so that applications can still run with a subset of providers available.
  void safeRegister(LLMProviderFactory factory) {
    try {
      LLMProviderRegistry.registerOrReplace(factory);
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
