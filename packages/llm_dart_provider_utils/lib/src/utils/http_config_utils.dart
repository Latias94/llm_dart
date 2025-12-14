import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import 'http_client_adapter_stub.dart'
    if (dart.library.io) 'http_client_adapter_io.dart'
    if (dart.library.html) 'http_client_adapter_web.dart';

/// HTTP configuration utilities for unified Dio setup across providers.
///
/// This is the shared implementation used by all providers via
/// `llm_dart_provider_utils`, and is re-exported by the main
/// `llm_dart` package for backwards compatibility.
class HttpConfigUtils {
  static LLMLogger _loggerFor(LLMConfig config) => resolveLogger(config);

  /// Create a configured Dio instance with unified HTTP settings.
  static Dio createConfiguredDio({
    required String baseUrl,
    required Map<String, String> defaultHeaders,
    required LLMConfig config,
    Duration? defaultTimeout,
  }) {
    final logger = _loggerFor(config);
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _getConnectionTimeout(config, defaultTimeout),
      receiveTimeout: _getReceiveTimeout(config, defaultTimeout),
      sendTimeout: _getSendTimeout(config, defaultTimeout),
      headers: _buildHeaders(defaultHeaders, config),
    );

    final dio = Dio(options);

    _configureHttpClientAdapter(dio, config);
    _configureLogging(dio, config, logger);
    _configureCustomInterceptors(dio, config);

    return dio;
  }

  static Duration _getConnectionTimeout(
    LLMConfig config,
    Duration? defaultTimeout,
  ) {
    final customTimeout =
        config.getExtension<Duration>(LLMConfigKeys.connectionTimeout);
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  static Duration _getReceiveTimeout(
    LLMConfig config,
    Duration? defaultTimeout,
  ) {
    final customTimeout =
        config.getExtension<Duration>(LLMConfigKeys.receiveTimeout);
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  static Duration _getSendTimeout(
    LLMConfig config,
    Duration? defaultTimeout,
  ) {
    final customTimeout =
        config.getExtension<Duration>(LLMConfigKeys.sendTimeout);
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  static Map<String, String> _buildHeaders(
    Map<String, String> defaultHeaders,
    LLMConfig config,
  ) {
    final customHeaders =
        config.getExtension<Map<String, String>>(LLMConfigKeys.customHeaders) ??
            <String, String>{};

    return {
      ...defaultHeaders,
      ...customHeaders,
    };
  }

  static void _configureHttpClientAdapter(Dio dio, LLMConfig config) {
    HttpClientAdapterConfig.configureHttpClientAdapter(dio, config);
  }

  static void _configureLogging(Dio dio, LLMConfig config, LLMLogger logger) {
    final enableLogging =
        config.getExtension<bool>(LLMConfigKeys.enableHttpLogging) ?? false;

    if (!enableLogging) return;

    logger.info('Enabling HTTP request/response logging');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.info('→ ${options.method} ${options.uri}');
          logger.fine('→ Headers: ${options.headers}');
          if (options.data != null) {
            logger.fine('→ Data: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.info(
            '← ${response.statusCode} ${response.requestOptions.uri}',
          );
          logger.fine('← Headers: ${response.headers}');
          handler.next(response);
        },
        onError: (error, handler) {
          logger.severe(
            '✗ ${error.requestOptions.method} ${error.requestOptions.uri}',
          );
          logger.severe('✗ Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  static void _configureCustomInterceptors(Dio dio, LLMConfig config) {
    final interceptors = config
        .getExtension<List<Interceptor>>(LLMConfigKeys.customInterceptors);
    if (interceptors == null || interceptors.isEmpty) return;

    for (final interceptor in interceptors) {
      dio.interceptors.add(interceptor);
    }
  }

  /// Simple Dio factory for providers that don't need advanced HTTP features.
  static Dio createSimpleDio({
    required String baseUrl,
    required Map<String, String> headers,
    Duration? timeout,
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout ?? const Duration(seconds: 60),
        receiveTimeout: timeout ?? const Duration(seconds: 60),
        headers: headers,
      ),
    );
  }

  static bool get isAdvancedHttpSupported =>
      HttpClientAdapterConfig.isAdvancedHttpSupported;

  static void validateHttpConfig(LLMConfig config) {
    final logger = _loggerFor(config);
    final connectionTimeout =
        config.getExtension<Duration>(LLMConfigKeys.connectionTimeout);
    final receiveTimeout =
        config.getExtension<Duration>(LLMConfigKeys.receiveTimeout);
    final globalTimeout = config.timeout;

    if (connectionTimeout != null &&
        globalTimeout != null &&
        connectionTimeout != globalTimeout) {
      logger.warning('Connection timeout differs from global timeout');
    }

    if (receiveTimeout != null &&
        globalTimeout != null &&
        receiveTimeout != globalTimeout) {
      logger.warning('Receive timeout differs from global timeout');
    }

    final bypassSSL =
        config.getExtension<bool>(LLMConfigKeys.bypassSSLVerification) ?? false;
    if (bypassSSL) {
      if (isAdvancedHttpSupported) {
        logger.warning(
          '⚠️ SSL verification is disabled - use only for development',
        );
      } else {
        logger.warning(
          '⚠️ SSL verification bypass is not supported on this platform',
        );
      }
    }

    final proxyUrl = config.getExtension<String>(LLMConfigKeys.httpProxy);
    if (proxyUrl != null) {
      if (!isAdvancedHttpSupported) {
        logger.warning(
          '⚠️ HTTP proxy configuration is not supported on this platform',
        );
      } else if (!proxyUrl.startsWith('http')) {
        logger.warning(
          'Proxy URL should start with http:// or https://',
        );
      }
    }

    final certificatePath =
        config.getExtension<String>(LLMConfigKeys.sslCertificate);
    if (certificatePath != null && !isAdvancedHttpSupported) {
      logger.warning(
        '⚠️ Custom SSL certificate loading is not supported on this platform',
      );
    }
  }
}
