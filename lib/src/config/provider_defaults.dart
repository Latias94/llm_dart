/// Centralized provider default configurations
///
/// This file contains legacy root config endpoint/model constants.
///
/// Capability declarations live on providers and factories, while
/// OpenAI-compatible generic endpoint profiles live in `OpenAICompatibleConfigs`.
class ProviderDefaults {
  // Core OpenAI
  static const String openaiBaseUrl = 'https://api.openai.com/v1/';
  static const String openaiDefaultModel = 'gpt-4o';

  // Anthropic
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1/';
  static const String anthropicDefaultModel = 'claude-sonnet-4-20250514';

  // Google (Gemini)
  static const String googleBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/';
  static const String googleDefaultModel = 'gemini-1.5-flash';

  // DeepSeek
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1/';
  static const String deepseekDefaultModel = 'deepseek-chat';

  // Groq
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1/';
  static const String groqDefaultModel = 'llama-3.3-70b-versatile';

  // xAI
  static const String xaiBaseUrl = 'https://api.x.ai/v1/';
  static const String xaiDefaultModel = 'grok-3';

  // Phind
  static const String phindBaseUrl = 'https://api.phind.com/v1/';
  static const String phindDefaultModel = 'Phind-70B';
}
