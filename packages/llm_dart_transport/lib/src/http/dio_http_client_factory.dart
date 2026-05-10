import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'dio_http_client_adapter_stub.dart'
    if (dart.library.io) 'dio_http_client_adapter_io.dart'
    if (dart.library.html) 'dio_http_client_adapter_web.dart';
import 'dio_http_client_config.dart';
import 'log_sanitizer.dart';

/// Transport-owned factory for reusable Dio client setup.
class DioHttpClientFactory {
  static const _defaultTimeout = Duration(seconds: 60);

  /// Create a configured Dio instance from transport-owned settings.
  static Dio createConfiguredDio({
    required DioHttpClientConfig config,
    Logger? logger,
  }) {
    final log = logger ?? Logger('DioHttpClientFactory');
    final options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: _resolveTimeout(
        config.connectionTimeout,
        config.timeout,
      ),
      receiveTimeout: _resolveTimeout(
        config.receiveTimeout,
        config.timeout,
      ),
      sendTimeout: _resolveTimeout(
        config.sendTimeout,
        config.timeout,
      ),
      headers: {
        ...config.defaultHeaders,
        ...config.customHeaders,
      },
    );

    final dio = Dio(options);
    DioHttpClientAdapterConfig.configureHttpClientAdapter(
      dio,
      config,
      logger: log,
    );
    _configureLogging(dio, config, log);
    return dio;
  }

  /// Create a simple Dio instance with minimal configuration.
  static Dio createSimpleDio({
    required String baseUrl,
    required Map<String, String> headers,
    Duration? timeout,
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout ?? _defaultTimeout,
        receiveTimeout: timeout ?? _defaultTimeout,
        headers: headers,
      ),
    );
  }

  /// Check if advanced HTTP features are supported on the current platform.
  static bool get isAdvancedHttpSupported =>
      DioHttpClientAdapterConfig.isAdvancedHttpSupported;

  /// Validate transport-owned HTTP client configuration.
  static void validateHttpConfig(
    DioHttpClientConfig config, {
    Logger? logger,
  }) {
    final log = logger ?? Logger('DioHttpClientFactory');
    final connectionTimeout = config.connectionTimeout;
    final receiveTimeout = config.receiveTimeout;
    final globalTimeout = config.timeout;

    if (connectionTimeout != null &&
        globalTimeout != null &&
        connectionTimeout != globalTimeout) {
      log.warning('Connection timeout differs from global timeout');
    }

    if (receiveTimeout != null &&
        globalTimeout != null &&
        receiveTimeout != globalTimeout) {
      log.warning('Receive timeout differs from global timeout');
    }

    if (config.bypassSslVerification) {
      if (isAdvancedHttpSupported) {
        log.warning(
          '⚠️ SSL verification is disabled - use only for development',
        );
      } else {
        log.warning(
          '⚠️ SSL verification bypass is not supported on this platform',
        );
      }
    }

    final proxyUrl = config.proxyUrl;
    if (proxyUrl != null) {
      if (!isAdvancedHttpSupported) {
        log.warning(
          '⚠️ HTTP proxy configuration is not supported on this platform',
        );
      } else if (_normalizeProxyHostPort(proxyUrl) == null) {
        log.warning('Proxy URL is invalid');
      }
    }

    final certificatePath = config.certificatePath;
    if (certificatePath != null && !isAdvancedHttpSupported) {
      log.warning(
        '⚠️ Custom SSL certificate loading is not supported on this platform',
      );
    }
  }

  static Duration _resolveTimeout(
    Duration? specificTimeout,
    Duration? defaultTimeout,
  ) {
    return specificTimeout ?? defaultTimeout ?? _defaultTimeout;
  }

  static void _configureLogging(
    Dio dio,
    DioHttpClientConfig config,
    Logger logger,
  ) {
    if (!config.enableLogging) {
      return;
    }

    logger.info('Enabling HTTP request/response logging');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.info('→ ${options.method} '
              '${LogSanitizer.sanitizeEndpoint(options.uri.toString())}');
          logger.fine(
            '→ Headers: ${LogSanitizer.sanitizeHeaders(options.headers)}',
          );
          if (options.data != null) {
            logger.fine('→ Data: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.info(
            '← ${response.statusCode} ${LogSanitizer.sanitizeEndpoint(
              response.requestOptions.uri.toString(),
            )}',
          );
          logger.fine(
            '← Headers: ${LogSanitizer.sanitizeHeaders(
              response.headers.map.cast<String, dynamic>(),
            )}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          logger.severe(
            '✗ ${error.requestOptions.method} '
            '${LogSanitizer.sanitizeEndpoint(
              error.requestOptions.uri.toString(),
            )}',
          );
          logger.severe('✗ Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  static String? _normalizeProxyHostPort(String proxyUrl) {
    final trimmed = proxyUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.contains('://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
        return null;
      }

      final port = uri.hasPort ? uri.port : _defaultProxyPort(uri.scheme);
      return '${uri.host}:$port';
    }

    if (trimmed.startsWith('PROXY ')) {
      final hostPort = trimmed.substring('PROXY '.length).trim();
      return hostPort.isEmpty ? null : hostPort;
    }

    return trimmed;
  }

  static int _defaultProxyPort(String scheme) {
    return scheme.toLowerCase() == 'https' ? 443 : 80;
  }
}
