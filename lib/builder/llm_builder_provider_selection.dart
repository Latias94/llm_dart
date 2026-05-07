part of 'llm_builder.dart';

extension LLMBuilderProviderSelection on LLMBuilder {
  /// Sets the provider to use (new registry-based approach)
  LLMBuilder provider(String providerId) => _setProvider(providerId);
}
