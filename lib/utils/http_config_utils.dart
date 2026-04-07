import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:logging/logging.dart';

import '../core/config.dart';
import '../src/config/legacy_config_extensions.dart';

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
    return DioHttpClientFactory.createConfiguredDio(
      config: _toTransportConfig(
        baseUrl: baseUrl,
        defaultHeaders: defaultHeaders,
        config: config,
        defaultTimeout: defaultTimeout,
      ),
      logger: _logger,
    );
  }

  /// Create a simple Dio instance with minimal configuration
  ///
  /// This is a fallback method for providers that don't need advanced HTTP features.
  static Dio createSimpleDio({
    required String baseUrl,
    required Map<String, String> headers,
    Duration? timeout,
  }) {
    return DioHttpClientFactory.createSimpleDio(
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Check if advanced HTTP features are supported on the current platform
  ///
  /// Returns true for platforms that support proxy, SSL configuration, etc.
  /// Returns false for web platform where these features are browser-managed.
  static bool get isAdvancedHttpSupported =>
      DioHttpClientFactory.isAdvancedHttpSupported;

  /// Validate HTTP configuration
  ///
  /// Checks for common configuration issues and logs warnings.
  static void validateHttpConfig(LLMConfig config) {
    DioHttpClientFactory.validateHttpConfig(
      _toTransportConfig(
        baseUrl: config.baseUrl,
        defaultHeaders: const <String, String>{},
        config: config,
      ),
      logger: _logger,
    );
  }

  static DioHttpClientConfig _toTransportConfig({
    required String baseUrl,
    required Map<String, String> defaultHeaders,
    required LLMConfig config,
    Duration? defaultTimeout,
  }) {
    return DioHttpClientConfig(
      baseUrl: baseUrl,
      defaultHeaders: defaultHeaders,
      customHeaders: config.legacyCustomHeaders,
      timeout: config.timeout ?? defaultTimeout,
      connectionTimeout: config.legacyConnectionTimeout,
      receiveTimeout: config.legacyReceiveTimeout,
      sendTimeout: config.legacySendTimeout,
      enableLogging: config.legacyEnableHttpLogging,
      proxyUrl: config.legacyHttpProxy,
      bypassSslVerification: config.legacyBypassSslVerification,
      certificatePath: config.legacySslCertificatePath,
    );
  }
}
