part of 'llm_builder.dart';

extension LLMBuilderProviderSelection on LLMBuilder {
  /// Sets the provider to use (new registry-based approach)
  LLMBuilder provider(String providerId) => _setProvider(providerId);

  LLMBuilder deepseek() => provider('deepseek');

  LLMBuilder xai() => provider('xai');
  LLMBuilder phind() => provider('phind');
  LLMBuilder groq() => provider('groq');

  /// Convenience methods for OpenAI-compatible providers
  /// These use the OpenAI interface but with provider-specific configurations
  LLMBuilder deepseekOpenAI() => provider('deepseek-openai');
  LLMBuilder googleOpenAI() => provider('google-openai');
  LLMBuilder xaiOpenAI() => provider('xai-openai');
  LLMBuilder groqOpenAI() => provider('groq-openai');
  LLMBuilder phindOpenAI() => provider('phind-openai');

  LLMBuilder githubCopilot() => provider('github-copilot');
  LLMBuilder togetherAI() => provider('together-ai');
}
