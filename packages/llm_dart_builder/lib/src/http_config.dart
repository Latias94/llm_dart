/// HTTP configuration builder for LLM providers
///
/// This class provides a fluent interface for configuring HTTP settings
/// separately from the main LLMBuilder to reduce method count.
class HttpConfig {
  final Map<String, dynamic> _config = {};

  /// Sets HTTP proxy configuration
  HttpConfig proxy(String proxyUrl) {
    _config['httpProxy'] = proxyUrl;
    return this;
  }

  /// Sets custom HTTP headers
  HttpConfig headers(Map<String, String> headers) {
    _config['customHeaders'] = headers;
    return this;
  }

  /// Sets a single custom HTTP header
  HttpConfig header(String name, String value) {
    final existingHeaders =
        _config['customHeaders'] as Map<String, String>? ?? <String, String>{};
    _config['customHeaders'] = {...existingHeaders, name: value};
    return this;
  }

  /// Enables SSL certificate verification bypass
  HttpConfig bypassSSLVerification(bool bypass) {
    _config['bypassSSLVerification'] = bypass;
    return this;
  }

  /// Sets custom SSL certificate path
  HttpConfig sslCertificate(String certificatePath) {
    _config['sslCertificate'] = certificatePath;
    return this;
  }

  /// Sets connection timeout
  HttpConfig connectionTimeout(Duration timeout) {
    _config['connectionTimeout'] = timeout;
    return this;
  }

  /// Sets receive timeout
  HttpConfig receiveTimeout(Duration timeout) {
    _config['receiveTimeout'] = timeout;
    return this;
  }

  /// Sets send timeout
  HttpConfig sendTimeout(Duration timeout) {
    _config['sendTimeout'] = timeout;
    return this;
  }

  /// Enables request/response logging for debugging
  HttpConfig enableLogging(bool enable) {
    _config['enableHttpLogging'] = enable;
    return this;
  }

  /// Provides a custom Dio client for full HTTP control
  ///
  /// This method allows you to provide your own pre-configured Dio instance
  /// with custom interceptors, adapters, and settings. This gives you complete
  /// control over HTTP behavior for advanced use cases.
  ///
  /// **Priority order:**
  /// 1. Custom Dio client (highest priority) - set by this method
  /// 2. HTTP configuration - set by other methods in this class
  /// 3. Provider defaults (lowest priority)
  ///
  /// **Important Notes:**
  /// - Provider-specific interceptors (like Anthropic's beta headers) will still be added
  /// - Your custom configuration takes precedence over other HTTP settings
  /// - Other HTTP configurations in this builder will be ignored when using custom Dio
  ///
  /// Example:
  /// ```dart
  /// // Create custom Dio with interceptors
  /// final customDio = Dio();
  /// customDio.options.connectTimeout = Duration(seconds: 30);
  /// customDio.interceptors.add(LogInterceptor());
  /// customDio.interceptors.add(MyCustomInterceptor());
  ///
  /// final provider = await ai()
  ///     .anthropic()
  ///     .apiKey('your-api-key')
  ///     .model('claude-sonnet-4-20250514')
  ///     .http((http) => http.dioClient(customDio))  // Full HTTP control
  ///     .build();
  /// ```
  ///
  /// This expects a Dio instance, but `llm_dart_builder` intentionally does not
  /// depend on Dio types. The value is passed through as `customDio` and will
  /// be consumed by provider implementations that use Dio.
  HttpConfig dioClient(Object dio) {
    _config['customDio'] = dio;
    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);
}
