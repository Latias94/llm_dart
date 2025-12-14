part of 'llm_builder.dart';

/// HTTP configuration helpers for [LLMBuilder].
extension LLMBuilderHttpExtensions on LLMBuilder {
  /// Configure HTTP settings using a fluent builder.
  ///
  /// This method provides a clean, organized way to configure HTTP settings
  /// without cluttering the main LLMBuilder interface.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .http((http) => http
  ///         .proxy('http://proxy.company.com:8080')
  ///         .headers({'X-Custom-Header': 'value'})
  ///         .connectionTimeout(Duration(seconds: 30))
  ///         .enableLogging(true))
  ///     .build();
  /// ```
  LLMBuilder http(HttpConfig Function(HttpConfig) configure) {
    final httpConfig = HttpConfig();
    final configuredHttp = configure(httpConfig);
    final httpSettings = configuredHttp.build();

    // Apply all HTTP settings as extensions
    for (final entry in httpSettings.entries) {
      extension(entry.key, entry.value);
    }

    // Convenience: when HTTP logging is enabled, automatically provide a
    // default logger implementation (unless the caller already provided one).
    final enableHttpLogging =
        httpSettings[LLMConfigKeys.enableHttpLogging] == true;
    if (enableHttpLogging &&
        currentConfig.getExtension<LLMLogger>(LLMConfigKeys.logger) == null) {
      extension(
        LLMConfigKeys.logger,
        const ConsoleLLMLogger(name: 'llm_dart.http'),
      );
    }

    return this;
  }
}
