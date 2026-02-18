import 'package:logging/logging.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_azure/llm_dart_azure.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_google_vertex/llm_dart_google_vertex.dart';
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
        _isRegistered('openai.chat') &&
        _isRegistered('azure') &&
        _isRegistered('azure.chat') &&
        _isRegistered('anthropic') &&
        _isRegistered('deepseek') &&
        _isRegistered('ollama') &&
        _isRegistered('google') &&
        _isRegistered('vertex') &&
        _isRegistered('google-vertex') &&
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

  /// Ensure a single provider id is registered (best-effort).
  ///
  /// This is intended for umbrella builder conveniences like:
  /// - `LLMBuilder().openai()`
  /// - `LLMBuilder().anthropic()`
  ///
  /// It avoids the global side effects of `ensureRegistered()` (which registers
  /// the full umbrella set).
  static void ensureProviderRegistered(String providerId) {
    final id = providerId.trim();
    if (id.isEmpty) return;
    if (_isRegistered(id)) return;

    final base = id.split('.').first;

    try {
      switch (base) {
        case 'openai':
          registerOpenAI();
          return;
        case 'azure':
          registerAzure();
          return;
        case 'anthropic':
          registerAnthropic();
          return;
        case 'google':
          registerGoogle();
          return;
        case 'vertex':
        case 'google-vertex':
          registerGoogleVertex();
          return;
        case 'deepseek':
          registerDeepSeek();
          return;
        case 'ollama':
          registerOllama();
          return;
        case 'xai':
          registerXAI();
          return;
        case 'groq':
          registerGroq();
          return;
        case 'elevenlabs':
          registerElevenLabs();
          return;
        case 'minimax':
          registerMinimax();
          return;
        case _openRouterProviderId:
          registerOpenAICompatibleProvider(_openRouterProviderId);
          return;
      }
    } catch (e) {
      _logger.warning('Failed to register provider "$providerId": $e');
      return;
    }

    _logger.warning(
      'Unknown built-in provider id "$providerId". '
      'This umbrella helper only supports first-party providers and OpenRouter. '
      'For other ids (e.g. OpenAI-compatible presets), register them explicitly '
      'or use `LLMBuilder().openaiCompatible("<id>")`.',
    );
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
      registerGoogleVertex();
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
