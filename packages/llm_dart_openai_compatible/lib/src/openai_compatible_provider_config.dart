import 'package:llm_dart_core/llm_dart_core.dart';

/// OpenAI-compatible provider configuration (no per-model matrices).
///
/// This type describes a provider that speaks an OpenAI-compatible API shape
/// (typically Chat Completions-like). It intentionally avoids any per-model
/// capability matrices or provider-side constraints enforcement.
class OpenAICompatibleProviderConfig {
  /// Provider identifier.
  final String providerId;

  /// Display name for UI.
  final String displayName;

  /// Provider description.
  final String description;

  /// Default base URL for API requests.
  final String defaultBaseUrl;

  /// Default model name.
  final String defaultModel;

  /// Best-effort capability set.
  ///
  /// This should be treated as a hint only; providers may reject requests at
  /// runtime depending on model and account settings.
  final Set<LLMCapability> supportedCapabilities;

  const OpenAICompatibleProviderConfig({
    required this.providerId,
    required this.displayName,
    required this.description,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.supportedCapabilities,
  });
}
