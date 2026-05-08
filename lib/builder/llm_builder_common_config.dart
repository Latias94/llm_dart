part of 'llm_builder.dart';

extension LLMBuilderCommonConfig on LLMBuilder {
  /// Sets the API key for authentication
  LLMBuilder apiKey(String key) => _setConfig(_config.copyWith(apiKey: key));

  /// Sets the base URL for API requests
  LLMBuilder baseUrl(String url) {
    final normalizedUrl = url.endsWith('/') ? url : '$url/';
    return _setConfig(_config.copyWith(baseUrl: normalizedUrl));
  }

  /// Sets the model identifier to use
  LLMBuilder model(String model) => _setConfig(_config.copyWith(model: model));

  /// Sets the maximum number of tokens to generate
  LLMBuilder maxTokens(int tokens) =>
      _setConfig(_config.copyWith(maxTokens: tokens));

  /// Sets the temperature for controlling response randomness (0.0-1.0)
  LLMBuilder temperature(double temp) =>
      _setConfig(_config.copyWith(temperature: temp));

  /// Sets the system prompt/context
  LLMBuilder systemPrompt(String prompt) =>
      _setConfig(_config.copyWith(systemPrompt: prompt));

  /// Sets the global timeout for all HTTP operations
  LLMBuilder timeout(Duration timeout) =>
      _setConfig(_config.copyWith(timeout: timeout));

  /// Sets the top-p (nucleus) sampling parameter
  LLMBuilder topP(double topP) => _setConfig(_config.copyWith(topP: topP));

  /// Sets the top-k sampling parameter
  LLMBuilder topK(int topK) => _setConfig(_config.copyWith(topK: topK));

  /// Sets the function tools
  LLMBuilder tools(List<Tool> tools) =>
      _setConfig(_config.copyWith(tools: tools));

  /// Sets the tool choice
  LLMBuilder toolChoice(ToolChoice choice) =>
      _setConfig(_config.copyWith(toolChoice: choice));

  /// Sets stop sequences for generation
  LLMBuilder stopSequences(List<String> sequences) =>
      _setConfig(_config.copyWith(stopSequences: sequences));

  /// Sets user identifier for tracking and analytics
  LLMBuilder user(String userId) => _setConfig(_config.copyWith(user: userId));

  /// Sets service tier for API requests
  LLMBuilder serviceTier(ServiceTier tier) =>
      _setConfig(_config.copyWith(serviceTier: tier));

  /// Sets a legacy compatibility extension.
  ///
  /// New provider-specific options should use typed provider builders, which
  /// store provider-owned values under providerOptions.
  LLMBuilder legacyExtension(String key, dynamic value) =>
      _setExtension(key, value);

  /// Gets the current configuration (for internal use by builders)
  LLMConfig get currentConfig => _config;

  /// Gets the currently selected provider ID.
  String? get currentProviderId => _providerId;

  /// Configure HTTP settings using a fluent builder
  LLMBuilder http(HttpConfig Function(HttpConfig) configure) {
    final httpConfig = HttpConfig();
    final configuredHttp = configure(httpConfig);
    final httpSettings = configuredHttp.build();
    return _applyHttpSettings(httpSettings);
  }
}
