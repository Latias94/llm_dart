import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'dio_http_client_config.dart';

/// Web platform implementation for HTTP client adapter configuration.
class DioHttpClientAdapterConfig {
  /// Configure HTTP client adapter with proxy and SSL settings.
  static void configureHttpClientAdapter(
    Dio dio,
    DioHttpClientConfig config, {
    required Logger logger,
  }) {
    final proxyUrl = config.proxyUrl;
    final bypassSslVerification = config.bypassSslVerification;
    final certificatePath = config.certificatePath;

    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      logger.warning(
        '⚠️ HTTP proxy configuration is not supported on web platform. '
        'Proxy setting "$proxyUrl" will be ignored.',
      );
    }

    if (bypassSslVerification) {
      logger.warning(
        '⚠️ SSL certificate verification bypass is not supported on web platform. '
        'SSL settings are managed by the browser.',
      );
    }

    if (certificatePath != null && certificatePath.isNotEmpty) {
      logger.warning(
        '⚠️ Custom SSL certificate loading is not supported on web platform. '
        'Certificate path "$certificatePath" will be ignored.',
      );
    }

    logger.info('Using default browser HTTP client for web platform');
  }

  /// Check if advanced HTTP features are supported on this platform.
  static bool get isAdvancedHttpSupported => false;
}
