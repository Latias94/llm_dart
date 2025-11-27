import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// HTTP configuration builder for LLM providers
///
/// This class provides a fluent interface for configuring HTTP settings
/// separately from the main LLMBuilder to reduce method count.
class HttpConfig {
  final Map<String, dynamic> _config = {};

  /// Sets HTTP proxy configuration
  HttpConfig proxy(String proxyUrl) {
    _config[LLMConfigKeys.httpProxy] = proxyUrl;
    return this;
  }

  /// Sets custom HTTP headers
  HttpConfig headers(Map<String, String> headers) {
    _config[LLMConfigKeys.customHeaders] = headers;
    return this;
  }

  /// Sets a single custom HTTP header
  HttpConfig header(String name, String value) {
    final existingHeaders =
        _config[LLMConfigKeys.customHeaders] as Map<String, String>? ??
            <String, String>{};
    _config[LLMConfigKeys.customHeaders] = {...existingHeaders, name: value};
    return this;
  }

  /// Enables SSL certificate verification bypass
  HttpConfig bypassSSLVerification(bool bypass) {
    _config[LLMConfigKeys.bypassSSLVerification] = bypass;
    return this;
  }

  /// Sets custom SSL certificate path
  HttpConfig sslCertificate(String certificatePath) {
    _config[LLMConfigKeys.sslCertificate] = certificatePath;
    return this;
  }

  /// Sets connection timeout
  HttpConfig connectionTimeout(Duration timeout) {
    _config[LLMConfigKeys.connectionTimeout] = timeout;
    return this;
  }

  /// Sets receive timeout
  HttpConfig receiveTimeout(Duration timeout) {
    _config[LLMConfigKeys.receiveTimeout] = timeout;
    return this;
  }

  /// Sets send timeout
  HttpConfig sendTimeout(Duration timeout) {
    _config[LLMConfigKeys.sendTimeout] = timeout;
    return this;
  }

  /// Enables request/response logging for debugging
  HttpConfig enableLogging(bool enable) {
    _config[LLMConfigKeys.enableHttpLogging] = enable;
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
  /// **Use Cases:**
  /// - Custom interceptors for monitoring/metrics
  /// - Advanced proxy configurations
  /// - Custom SSL/TLS settings
  /// - Integration with existing HTTP infrastructure
  /// - Testing with mock interceptors
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
  HttpConfig dioClient(Dio dio) {
    _config[LLMConfigKeys.customDio] = dio;
    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);
}
