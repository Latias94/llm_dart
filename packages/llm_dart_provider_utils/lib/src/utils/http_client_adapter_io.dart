import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logging/logging.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// IO platform implementation for HTTP client adapter configuration.
class HttpClientAdapterConfig {
  static final Logger _logger = Logger('HttpClientAdapterConfig');

  /// Configure HTTP client adapter with proxy and SSL settings.
  static void configureHttpClientAdapter(Dio dio, LLMConfig config) {
    final proxyUrl = config.getExtension<String>(LLMConfigKeys.httpProxy);
    final bypassSSL =
        config.getExtension<bool>(LLMConfigKeys.bypassSSLVerification) ?? false;
    final certificatePath =
        config.getExtension<String>(LLMConfigKeys.sslCertificate);

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

      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();

          if (proxyUrl != null && proxyUrl.isNotEmpty) {
            client.findProxy = (uri) => 'PROXY $proxyUrl';
          }

          if (bypassSSL) {
            client.badCertificateCallback = (cert, host, port) => true;
          }

          if (certificatePath != null && certificatePath.isNotEmpty) {
            try {
              final certFile = File(certificatePath);
              if (certFile.existsSync()) {
                _logger.info('SSL certificate loaded successfully');
              } else {
                _logger.warning(
                  'SSL certificate file not found: $certificatePath',
                );
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

  /// Check if advanced HTTP features are supported on this platform.
  static bool get isAdvancedHttpSupported => true;
}
