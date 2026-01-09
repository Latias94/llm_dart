import 'package:logging/logging.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_azure/llm_dart_azure.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Registration helpers for the umbrella `llm_dart` package.
///
/// This is intentionally separated from `core/registry.dart` to avoid core→provider
/// coupling and to enable splitting providers into independent packages.
class BuiltinProviderRegistry {
  static final Logger _logger = Logger('BuiltinProviderRegistry');

  static bool _isRegistered(String providerId) =>
      LLMProviderRegistry.isRegistered(providerId);

  static const String _openRouterProviderId = 'openrouter';

  /// Ensure the Vercel-style "standard" providers are registered.
  ///
  /// In `llm_dart`, "standard" means the first-party providers we align with
  /// Vercel AI SDK: OpenAI, Anthropic, and Google (Gemini).
  ///
  /// Other providers may still exist in the umbrella package, but they are not
  /// considered part of the "standard providers" set.
  static void ensureStandardRegistered() {
    if (_isRegistered('openai') &&
        _isRegistered('anthropic') &&
        _isRegistered('google')) {
      return;
    }
    registerStandard();
  }

  /// Ensure built-in providers are registered.
  ///
  /// Umbrella entrypoints like `ai()` call this to keep the default UX unchanged,
  /// while still allowing low-level users to manage the registry manually.
  static void ensureRegistered() {
    if (_isRegistered('openai') &&
        _isRegistered('azure') &&
        _isRegistered('anthropic') &&
        _isRegistered('deepseek') &&
        _isRegistered('ollama') &&
        _isRegistered('google') &&
        _isRegistered('xai') &&
        _isRegistered('xai.responses') &&
        _isRegistered('groq') &&
        _isRegistered('elevenlabs') &&
        _isRegistered('minimax') &&
        _isRegistered(_openRouterProviderId)) {
      return;
    }
    registerAll();
  }

  /// Ensure a specific OpenAI-compatible preset provider is registered.
  ///
  /// `llm_dart` treats OpenAI-compatible presets as opt-in because some of them
  /// are duplicates of first-party provider packages (e.g. `deepseek` vs
  /// `deepseek-openai`).
  ///
  /// The umbrella package still ships helper builders for these presets; those
  /// helpers call this method so the provider id is available on demand.
  static void ensureOpenAICompatibleProviderRegistered(
    String providerId, {
    bool replace = false,
  }) {
    try {
      registerOpenAICompatibleProvider(providerId, replace: replace);
    } catch (e) {
      _logger.warning('Failed to register OpenAI-compatible provider: $e');
    }
  }

  /// Register the "standard" provider set (OpenAI, Anthropic, Google).
  static void registerStandard() {
    try {
      registerOpenAI();
      registerAnthropic();
      registerGoogle();
    } catch (e) {
      _logger.warning('Failed to register standard providers: $e');
    }
  }

  /// Register all built-in providers shipped in the umbrella package.
  static void registerAll() {
    try {
      registerOpenAI();
      registerAzure();
      registerAnthropic();
      registerDeepSeek();
      registerOllama();
      registerGoogle();
      registerXAI();
      registerGroq();
      registerElevenLabs();
      registerMinimax();

      // Register OpenRouter by default because the umbrella package provides
      // first-class OpenRouter helpers (see `OpenRouterBuilder`).
      //
      // Other OpenAI-compatible presets are opt-in to avoid silently registering
      // duplicate provider ids (e.g. `deepseek` vs `deepseek-openai`).
      registerOpenAICompatibleProvider(_openRouterProviderId);
    } catch (e) {
      _logger.warning('Failed to register built-in providers: $e');
    }
  }

  // OpenAI-compatible presets can still be registered explicitly via:
  // - `registerOpenAICompatibleProviders()` (all presets), or
  // - `registerOpenAICompatibleProvider(id)` (a single preset).
}
