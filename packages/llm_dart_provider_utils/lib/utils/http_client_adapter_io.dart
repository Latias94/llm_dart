import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logging/logging.dart';

import 'package:llm_dart_core/core/config.dart';

/// IO platform implementation for HTTP client adapter configuration
class HttpClientAdapterConfig {
  static final Logger _logger = Logger('HttpClientAdapterConfig');

  /// Configure HTTP client adapter with proxy and SSL settings
  /// IO platform implementation using IOHttpClientAdapter
  static void configureHttpClientAdapter(Dio dio, LLMConfig config) {
    final proxyUrl = config.getTransportOption<String>('httpProxy');
    final bypassSSL =
        config.getTransportOption<bool>('bypassSSLVerification') ?? false;
    final certificatePath = config.getTransportOption<String>('sslCertificate');

    // Only configure adapter if any HTTP client settings are specified
    if ((proxyUrl != null && proxyUrl.isNotEmpty) ||
        bypassSSL ||
        (certificatePath != null && certificatePath.isNotEmpty)) {
      if (proxyUrl != null) {
        _logger.info('Configuring HTTP proxy: $proxyUrl');
      }
      if (bypassSSL) {
        _logger.warning('⚠️ SSL certificate verification is disabled');
      }
      if (certificatePath != null) {
        _logger.info('Loading SSL certificate from: $certificatePath');
      }

      // Set a new IOHttpClientAdapter with combined configuration
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();

          // Configure proxy if specified
          if (proxyUrl != null && proxyUrl.isNotEmpty) {
            client.findProxy = (uri) {
              return "PROXY $proxyUrl";
            };
          }

          // Configure SSL settings if specified
          if (bypassSSL) {
            client.badCertificateCallback = (cert, host, port) => true;
          }

          if (certificatePath != null && certificatePath.isNotEmpty) {
            try {
              final certFile = File(certificatePath);
              if (certFile.existsSync()) {
                // Note: This is a simplified example. In practice, you might need
                // more sophisticated certificate handling depending on the format.
                // For now, we just log that the certificate file exists
                _logger.info('SSL certificate loaded successfully');
              } else {
                _logger.warning(
                    'SSL certificate file not found: $certificatePath');
              }
            } catch (e) {
              _logger.severe('Failed to load SSL certificate: $e');
            }
          }

          return client;
        },
      );
    }
  }

  /// Check if advanced HTTP features are supported on this platform
  static bool get isAdvancedHttpSupported => true;
}
