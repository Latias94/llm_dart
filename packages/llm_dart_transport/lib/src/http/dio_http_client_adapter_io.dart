import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logging/logging.dart';

import 'dio_http_client_config.dart';

/// IO platform implementation for HTTP client adapter configuration.
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

    if ((proxyUrl != null && proxyUrl.isNotEmpty) ||
        bypassSslVerification ||
        (certificatePath != null && certificatePath.isNotEmpty)) {
      if (proxyUrl != null) {
        logger.info('Configuring HTTP proxy: $proxyUrl');
      }
      if (bypassSslVerification) {
        logger.warning('⚠️ SSL certificate verification is disabled');
      }
      if (certificatePath != null) {
        logger.info('Loading SSL certificate from: $certificatePath');
      }

      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();

          if (proxyUrl != null && proxyUrl.isNotEmpty) {
            client.findProxy = (uri) {
              return 'PROXY $proxyUrl';
            };
          }

          if (bypassSslVerification) {
            client.badCertificateCallback = (cert, host, port) => true;
          }

          if (certificatePath != null && certificatePath.isNotEmpty) {
            try {
              final certFile = File(certificatePath);
              if (certFile.existsSync()) {
                logger.info('SSL certificate loaded successfully');
              } else {
                logger.warning(
                  'SSL certificate file not found: $certificatePath',
                );
              }
            } catch (error) {
              logger.severe('Failed to load SSL certificate: $error');
            }
          }

          return client;
        },
      );
    }
  }

  /// Check if advanced HTTP features are supported on this platform.
  static bool get isAdvancedHttpSupported => true;
}
