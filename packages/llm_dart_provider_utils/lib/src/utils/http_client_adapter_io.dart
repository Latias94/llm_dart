import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// IO platform implementation for HTTP client adapter configuration.
class HttpClientAdapterConfig {
  /// Configure HTTP client adapter with proxy and SSL settings.
  static void configureHttpClientAdapter(Dio dio, LLMConfig config) {
    final logger = resolveLogger(config);
    final proxyUrl = config.getExtension<String>(LLMConfigKeys.httpProxy);
    final bypassSSL =
        config.getExtension<bool>(LLMConfigKeys.bypassSSLVerification) ?? false;
    final certificatePath =
        config.getExtension<String>(LLMConfigKeys.sslCertificate);

    if ((proxyUrl != null && proxyUrl.isNotEmpty) ||
        bypassSSL ||
        (certificatePath != null && certificatePath.isNotEmpty)) {
      if (proxyUrl != null && proxyUrl.isNotEmpty) {
        logger.info('Configuring HTTP proxy: $proxyUrl');
      }
      if (bypassSSL) {
        logger.warning('⚠️ SSL certificate verification is disabled');
      }
      if (certificatePath != null && certificatePath.isNotEmpty) {
        logger.info('Loading SSL certificate from: $certificatePath');
      }

      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          SecurityContext? context;

          // When a custom certificate is provided, extend the default trusted
          // roots with the additional certificate. This is useful for
          // private CAs or self-signed certificates.
          if (certificatePath != null && certificatePath.isNotEmpty) {
            try {
              final certFile = File(certificatePath);
              if (certFile.existsSync()) {
                context = SecurityContext(withTrustedRoots: true)
                  ..setTrustedCertificates(certificatePath);
                logger.info('SSL certificate loaded successfully');
              } else {
                logger.warning(
                  'SSL certificate file not found: $certificatePath',
                );
              }
            } catch (e) {
              logger.severe('Failed to load SSL certificate: $e', e);
            }
          }

          final client =
              context != null ? HttpClient(context: context) : HttpClient();

          if (proxyUrl != null && proxyUrl.isNotEmpty) {
            client.findProxy = (uri) => 'PROXY $proxyUrl';
          }

          if (bypassSSL) {
            client.badCertificateCallback = (cert, host, port) => true;
          }

          return client;
        },
      );
    }
  }

  /// Check if advanced HTTP features are supported on this platform.
  static bool get isAdvancedHttpSupported => true;
}
