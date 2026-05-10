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
            final findProxyValue = _normalizeProxyHostPort(proxyUrl);
            client.findProxy = (uri) {
              if (findProxyValue == null) {
                return 'DIRECT';
              }
              return 'PROXY $findProxyValue';
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

String? _normalizeProxyHostPort(String proxyUrl) {
  final trimmed = proxyUrl.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final uri = trimmed.contains('://') ? Uri.tryParse(trimmed) : null;
  if (uri != null && uri.hasAuthority && uri.host.isNotEmpty) {
    final port = uri.hasPort ? uri.port : _defaultProxyPort(uri.scheme);
    return '${uri.host}:$port';
  }

  if (trimmed.startsWith('PROXY ')) {
    return trimmed.substring('PROXY '.length).trim();
  }

  return trimmed;
}

int _defaultProxyPort(String scheme) {
  return scheme.toLowerCase() == 'https' ? 443 : 80;
}
