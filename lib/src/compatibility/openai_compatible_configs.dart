import '../../core/capability.dart';
import '../config/provider_defaults.dart';
import 'openai_compatible_provider_config.dart';

part 'openai_compatible_provider_profiles.dart';

/// Pre-configured OpenAI-compatible provider configurations.
///
/// Dedicated providers such as DeepSeek, Google, Groq, Phind, and xAI are no
/// longer duplicated here as `*-openai` aliases. They own their provider
/// options through first-class facades. This registry is for OpenAI-family
/// endpoints that either need a special compatibility bridge, like OpenRouter,
/// or do not yet have a dedicated provider facade.
class OpenAICompatibleConfigs {
  /// OpenRouter configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig openRouter =
      _openRouterOpenAICompatibleConfig;

  /// GitHub Copilot Chat API using the generic OpenAI-family compatibility path.
  static const OpenAICompatibleProviderConfig githubCopilot =
      _githubCopilotOpenAICompatibleConfig;

  /// Together AI using the generic OpenAI-family compatibility path.
  static const OpenAICompatibleProviderConfig togetherAI =
      _togetherAIOpenAICompatibleConfig;

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
