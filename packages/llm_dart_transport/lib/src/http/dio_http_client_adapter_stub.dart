import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'dio_http_client_config.dart';

/// Stub implementation for HTTP client adapter configuration.
class DioHttpClientAdapterConfig {
  /// Configure HTTP client adapter with proxy and SSL settings.
  ///
  /// This stub should never be used directly. Platform-specific conditional
  /// imports should select the real implementation instead.
  static void configureHttpClientAdapter(
    Dio dio,
    DioHttpClientConfig config, {
    required Logger logger,
  }) {
    throw UnsupportedError(
      'HTTP client adapter configuration is not supported on this platform. '
      'This is a stub implementation that should not be called.',
    );
  }

  /// Check if advanced HTTP features are supported on this platform.
  static bool get isAdvancedHttpSupported => false;
}
