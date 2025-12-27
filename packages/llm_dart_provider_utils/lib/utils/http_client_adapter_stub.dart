import 'package:dio/dio.dart';

import 'package:llm_dart_core/core/config.dart';

/// Stub implementation for HTTP client adapter configuration
/// This file should never be used directly - it's only for conditional imports
class HttpClientAdapterConfig {
  /// Configure HTTP client adapter with proxy and SSL settings
  /// Stub implementation that throws an error
  static void configureHttpClientAdapter(Dio dio, LLMConfig config) {
    throw UnsupportedError(
      'HTTP client adapter configuration is not supported on this platform. '
      'This is a stub implementation that should not be called.',
    );
  }

  /// Check if advanced HTTP features are supported on this platform
  static bool get isAdvancedHttpSupported => false;
}
