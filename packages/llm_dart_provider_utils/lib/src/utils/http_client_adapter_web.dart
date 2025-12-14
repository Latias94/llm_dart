import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Web platform implementation for HTTP client adapter configuration.
class HttpClientAdapterConfig {
  /// Configure HTTP client adapter with proxy and SSL settings.
  /// On web, these are managed by the browser so we only log warnings.
  static void configureHttpClientAdapter(Dio dio, LLMConfig config) {
    final logger = resolveLogger(config);
    final proxyUrl = config.getExtension<String>(LLMConfigKeys.httpProxy);
    final bypassSSL =
        config.getExtension<bool>(LLMConfigKeys.bypassSSLVerification) ?? false;
    final certificatePath =
        config.getExtension<String>(LLMConfigKeys.sslCertificate);

    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      logger.warning(
        '⚠️ HTTP proxy configuration is not supported on web platform. '
        'Proxy setting "$proxyUrl" will be ignored.',
      );
    }

    if (bypassSSL) {
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
