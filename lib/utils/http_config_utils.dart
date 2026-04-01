import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../core/config.dart';
import '../src/config/legacy_config_extensions.dart';
import 'http_client_adapter_stub.dart'
    if (dart.library.io) 'http_client_adapter_io.dart'
    if (dart.library.html) 'http_client_adapter_web.dart';

/// HTTP configuration utilities for unified Dio setup across providers
///
/// This class provides common HTTP configuration functionality that can be
/// used by all providers to support features like proxies, custom headers,
/// SSL configuration, and logging.
class HttpConfigUtils {
  static final Logger _logger = Logger('HttpConfigUtils');

  /// Create a configured Dio instance with unified HTTP settings
  ///
  /// This method applies common HTTP configurations from LLMConfig extensions
  /// while allowing provider-specific customizations.
  static Dio createConfiguredDio({
    required String baseUrl,
    required Map<String, String> defaultHeaders,
    required LLMConfig config,
    Duration? defaultTimeout,
  }) {
    // Start with base options
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _getConnectionTimeout(config, defaultTimeout),
      receiveTimeout: _getReceiveTimeout(config, defaultTimeout),
      sendTimeout: _getSendTimeout(config, defaultTimeout),
      headers: _buildHeaders(defaultHeaders, config),
    );

    final dio = Dio(options);

    // Configure HTTP client adapter with proxy and SSL settings
    _configureHttpClientAdapter(dio, config);

    // Add logging interceptor if enabled
    _configureLogging(dio, config);

    return dio;
  }

  /// Get connection timeout from config or use default
  static Duration _getConnectionTimeout(
      LLMConfig config, Duration? defaultTimeout) {
    final customTimeout = config.legacyConnectionTimeout;
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  /// Get receive timeout from config or use default
  static Duration _getReceiveTimeout(
      LLMConfig config, Duration? defaultTimeout) {
    final customTimeout = config.legacyReceiveTimeout;
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  /// Get send timeout from config or use default
  static Duration _getSendTimeout(LLMConfig config, Duration? defaultTimeout) {
    final customTimeout = config.legacySendTimeout;
    return customTimeout ??
        config.timeout ??
        defaultTimeout ??
        const Duration(seconds: 60);
  }

  /// Build headers by merging default headers with custom headers
  static Map<String, String> _buildHeaders(
    Map<String, String> defaultHeaders,
    LLMConfig config,
  ) {
    // Merge headers, with custom headers taking precedence
    return {
      ...defaultHeaders,
      ...config.legacyCustomHeaders,
    };
  }

  /// Configure HTTP client adapter with proxy and SSL settings
  static void _configureHttpClientAdapter(Dio dio, LLMConfig config) {
    // Use platform-specific HTTP client adapter configuration
    HttpClientAdapterConfig.configureHttpClientAdapter(dio, config);
  }

  /// Configure logging interceptor if enabled
  static void _configureLogging(Dio dio, LLMConfig config) {
    final enableLogging = config.legacyEnableHttpLogging;

    if (enableLogging) {
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
                '← ${response.statusCode} ${response.requestOptions.uri}');
            _logger.fine('← Headers: ${response.headers}');
            handler.next(response);
          },
          onError: (error, handler) {
            _logger.severe(
                '✗ ${error.requestOptions.method} ${error.requestOptions.uri}');
            _logger.severe('✗ Error: ${error.message}');
            handler.next(error);
          },
        ),
      );
    }
  }

  /// Create a simple Dio instance with minimal configuration
  ///
  /// This is a fallback method for providers that don't need advanced HTTP features.
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

  /// Check if advanced HTTP features are supported on the current platform
  ///
  /// Returns true for platforms that support proxy, SSL configuration, etc.
  /// Returns false for web platform where these features are browser-managed.
  static bool get isAdvancedHttpSupported =>
      HttpClientAdapterConfig.isAdvancedHttpSupported;

  /// Validate HTTP configuration
  ///
  /// Checks for common configuration issues and logs warnings.
  static void validateHttpConfig(LLMConfig config) {
    // Check for conflicting timeout settings
    final connectionTimeout = config.legacyConnectionTimeout;
    final receiveTimeout = config.legacyReceiveTimeout;
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

    // Check for security issues
    final bypassSSL = config.legacyBypassSslVerification;
    if (bypassSSL) {
      if (isAdvancedHttpSupported) {
        _logger.warning(
            '⚠️ SSL verification is disabled - use only for development');
      } else {
        _logger.warning(
            '⚠️ SSL verification bypass is not supported on this platform');
      }
    }

    // Check proxy configuration
    final proxyUrl = config.legacyHttpProxy;
    if (proxyUrl != null) {
      if (!isAdvancedHttpSupported) {
        _logger.warning(
            '⚠️ HTTP proxy configuration is not supported on this platform');
      } else if (!proxyUrl.startsWith('http')) {
        _logger.warning('Proxy URL should start with http:// or https://');
      }
    }

    // Check SSL certificate configuration
    final certificatePath = config.legacySslCertificatePath;
    if (certificatePath != null && !isAdvancedHttpSupported) {
      _logger.warning(
          '⚠️ Custom SSL certificate loading is not supported on this platform');
    }
  }
}
