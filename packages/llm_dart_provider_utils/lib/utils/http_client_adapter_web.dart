import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'package:llm_dart_core/core/config.dart';

/// Web platform implementation for HTTP client adapter configuration
class HttpClientAdapterConfig {
  static final Logger _logger = Logger('HttpClientAdapterConfig');

  /// Configure HTTP client adapter with proxy and SSL settings
  /// Web platform implementation with limited functionality
  static void configureHttpClientAdapter(Dio dio, LLMConfig config) {
    final proxyUrl = config.getTransportOption<String>('httpProxy');
    final bypassSSL =
        config.getTransportOption<bool>('bypassSSLVerification') ?? false;
    final certificatePath = config.getTransportOption<String>('sslCertificate');

    // Log warnings for unsupported features on web platform
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      _logger.warning(
          '⚠️ HTTP proxy configuration is not supported on web platform. '
          'Proxy setting "$proxyUrl" will be ignored.');
    }

    if (bypassSSL) {
      _logger.warning(
          '⚠️ SSL certificate verification bypass is not supported on web platform. '
          'SSL settings are managed by the browser.');
    }

    if (certificatePath != null && certificatePath.isNotEmpty) {
      _logger.warning(
          '⚠️ Custom SSL certificate loading is not supported on web platform. '
          'Certificate path "$certificatePath" will be ignored.');
    }

    // On web platform, we don't need to configure a custom adapter
    // The browser handles HTTP requests and SSL/TLS configuration
    _logger.info('Using default browser HTTP client for web platform');
  }

  /// Check if advanced HTTP features are supported on this platform
  static bool get isAdvancedHttpSupported => false;
}
