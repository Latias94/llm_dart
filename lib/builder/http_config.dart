import 'package:llm_dart_transport/llm_dart_transport.dart';

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

  /// Provides a custom transport client for advanced HTTP control.
  ///
  /// This is the preferred injection point for migrated providers and
  /// compatibility bridges. When the provided client is backed by Dio,
  /// legacy fallback paths can also reuse the same underlying client.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai()
  ///     .apiKey('your-api-key')
  ///     .model('gpt-4.1')
  ///     .http((http) => http.transportClient(MyTransportClient()))
  ///     .build();
  /// ```
  HttpConfig transportClient(TransportClient client) {
    _config['customTransportClient'] = client;

    if (client case DioTransportClient(:final dio)) {
      _config['customDio'] = dio;
    }

    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);
}
