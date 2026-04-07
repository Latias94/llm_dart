/// Transport-owned configuration for reusable Dio client setup.
final class DioHttpClientConfig {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Map<String, String> customHeaders;
  final Duration? timeout;
  final Duration? connectionTimeout;
  final Duration? receiveTimeout;
  final Duration? sendTimeout;
  final bool enableLogging;
  final String? proxyUrl;
  final bool bypassSslVerification;
  final String? certificatePath;

  const DioHttpClientConfig({
    required this.baseUrl,
    required this.defaultHeaders,
    this.customHeaders = const <String, String>{},
    this.timeout,
    this.connectionTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.enableLogging = false,
    this.proxyUrl,
    this.bypassSslVerification = false,
    this.certificatePath,
  });
}
