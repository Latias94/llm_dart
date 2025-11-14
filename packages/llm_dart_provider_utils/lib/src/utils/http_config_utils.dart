import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
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
  static final Logger _logger = Logger('HttpConfigUtils');

  /// Create a configured Dio instance with unified HTTP settings.
  static Dio createConfiguredDio({
    required String baseUrl,
    required Map<String, String> defaultHeaders,
    required LLMConfig config,
    Duration? defaultTimeout,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _getConnectionTimeout(config, defaultTimeout),
      receiveTimeout: _getReceiveTimeout(config, defaultTimeout),
      sendTimeout: _getSendTimeout(config, defaultTimeout),
      headers: _buildHeaders(defaultHeaders, config),
    );

    final dio = Dio(options);

    _configureHttpClientAdapter(dio, config);
    _configureLogging(dio, config);

    return dio;
  }

  static Duration _getConnectionTimeout(
    LLMConfig config,
    Duration? defaultTimeout,
  ) {
    final customTimeout = config.getExtension<Duration>('connectionTimeout');
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  static Duration _getReceiveTimeout(
    LLMConfig config,
    Duration? defaultTimeout,
  ) {
    final customTimeout = config.getExtension<Duration>('receiveTimeout');
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  static Duration _getSendTimeout(
    LLMConfig config,
    Duration? defaultTimeout,
  ) {
    final customTimeout = config.getExtension<Duration>('sendTimeout');
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
        config.getExtension<Map<String, String>>('customHeaders') ??
            <String, String>{};

    return {
      ...defaultHeaders,
      ...customHeaders,
    };
  }

  static void _configureHttpClientAdapter(Dio dio, LLMConfig config) {
    HttpClientAdapterConfig.configureHttpClientAdapter(dio, config);
  }

  static void _configureLogging(Dio dio, LLMConfig config) {
    final enableLogging =
        config.getExtension<bool>('enableHttpLogging') ?? false;

    if (!enableLogging) return;

    _logger.info('Enabling HTTP request/response logging');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.info('→ ${options.method} ${options.uri}');
          _logger.fine('→ Headers: ${options.headers}');
          if (options.data != null) {
            _logger.fine('→ Data: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.info(
            '← ${response.statusCode} ${response.requestOptions.uri}',
          );
          _logger.fine('← Headers: ${response.headers}');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.severe(
            '✗ ${error.requestOptions.method} ${error.requestOptions.uri}',
          );
          _logger.severe('✗ Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
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
    final connectionTimeout =
        config.getExtension<Duration>('connectionTimeout');
    final receiveTimeout = config.getExtension<Duration>('receiveTimeout');
    final globalTimeout = config.timeout;

    if (connectionTimeout != null &&
        globalTimeout != null &&
        connectionTimeout != globalTimeout) {
      _logger.warning('Connection timeout differs from global timeout');
    }

    if (receiveTimeout != null &&
        globalTimeout != null &&
        receiveTimeout != globalTimeout) {
      _logger.warning('Receive timeout differs from global timeout');
    }

    final bypassSSL =
        config.getExtension<bool>('bypassSSLVerification') ?? false;
    if (bypassSSL) {
      if (isAdvancedHttpSupported) {
        _logger.warning(
          '⚠️ SSL verification is disabled - use only for development',
        );
      } else {
        _logger.warning(
          '⚠️ SSL verification bypass is not supported on this platform',
        );
      }
    }

    final proxyUrl = config.getExtension<String>('httpProxy');
    if (proxyUrl != null) {
      if (!isAdvancedHttpSupported) {
        _logger.warning(
          '⚠️ HTTP proxy configuration is not supported on this platform',
        );
      } else if (!proxyUrl.startsWith('http')) {
        _logger.warning(
          'Proxy URL should start with http:// or https://',
        );
      }
    }

    final certificatePath = config.getExtension<String>('sslCertificate');
    if (certificatePath != null && !isAdvancedHttpSupported) {
      _logger.warning(
        '⚠️ Custom SSL certificate loading is not supported on this platform',
      );
    }
  }
}
