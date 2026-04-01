part of 'llm_builder.dart';

extension _LLMBuilderInternals on LLMBuilder {
  LLMBuilder _setProvider(String providerId) {
    _providerId = providerId;

    final factory = LLMProviderRegistry.getFactory(providerId);
    if (factory != null) {
      _config = factory.getDefaultConfig();
    }

    return this;
  }

  LLMBuilder _setConfig(LLMConfig config) {
    _config = config;
    return this;
  }

  LLMBuilder _setExtension(String key, dynamic value) {
    _config = _config.withExtension(key, value);
    return this;
  }

  LLMBuilder _applyHttpSettings(Map<String, dynamic> settings) {
    for (final entry in settings.entries) {
      _config = _config.withExtension(entry.key, entry.value);
    }

    return this;
  }

  WebSearchConfig? get _currentWebSearchConfig =>
      _config.getExtension<WebSearchConfig>('webSearchConfig');

  Future<T> _buildCapability<T extends Object>({
    required String unsupportedMessage,
  }) async {
    final provider = await build();
    if (provider is! T) {
      throw UnsupportedCapabilityError(unsupportedMessage);
    }

    return provider as T;
  }
}
