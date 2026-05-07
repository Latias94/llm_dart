import '../../core/capability.dart';
import '../config/provider_defaults.dart';
import 'google_openai_transformers.dart';
import 'openai_compatible_provider_config.dart';

part 'openai_compatible_provider_profiles.dart';

/// Pre-configured OpenAI-compatible provider configurations
///
/// This file contains configurations for popular AI providers that offer
/// OpenAI-compatible APIs, making it easy for users to switch between
/// providers without manual configuration.
class OpenAICompatibleConfigs {
  /// DeepSeek configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig deepseek =
      _deepseekOpenAICompatibleConfig;

  /// Google Gemini configuration using OpenAI-compatible interface
  static final OpenAICompatibleProviderConfig gemini =
      _geminiOpenAICompatibleConfig;

  /// xAI Grok configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig xai = _xaiOpenAICompatibleConfig;

  /// Groq configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig groq =
      _groqOpenAICompatibleConfig;

  /// Phind configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig phind =
      _phindOpenAICompatibleConfig;

  /// OpenRouter configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig openRouter =
      _openRouterOpenAICompatibleConfig;

  /// Get all available OpenAI-compatible configurations
  static List<OpenAICompatibleProviderConfig> getAllConfigs() {
    return List<OpenAICompatibleProviderConfig>.of(
      _openAICompatibleProviderProfiles,
    );
  }

  /// Get configuration by provider ID
  static OpenAICompatibleProviderConfig? getConfig(String providerId) {
    return _openAICompatibleProviderProfilesById[providerId];
  }

  /// Check if a provider ID is OpenAI-compatible
  static bool isOpenAICompatible(String providerId) {
    return getConfig(providerId) != null;
  }

  /// Get model capabilities for a specific provider and model
  static ModelCapabilityConfig? getModelCapabilities(
      String providerId, String model) {
    final config = getConfig(providerId);
    return config?.modelConfigs[model];
  }
}
