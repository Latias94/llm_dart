import 'package:dio/dio.dart';
import '../core/base_http_provider.dart';
import '../core/config.dart';

/// Strategy interface for provider-specific Dio configuration
///
/// Each provider implements this interface to define their specific
/// requirements for HTTP client setup, including headers, authentication,
/// and custom enhancements.
abstract class ProviderDioStrategy {
  /// Provider name for logging and debugging
  String get providerName;

  /// Build provider-specific HTTP headers
  Map<String, String> buildHeaders(dynamic config);

  /// Get list of provider-specific enhancers
  List<DioEnhancer> getEnhancers(dynamic config);

  /// Get base URL for the provider
  String getBaseUrl(dynamic config);

  /// Get timeout configuration
  Duration? getTimeout(dynamic config);
}

/// Interface for composable Dio enhancements
///
/// Enhancers can add interceptors, modify configuration, or apply
/// other customizations to a Dio instance. They are applied in order
/// and can be combined flexibly.
abstract class DioEnhancer {
  /// Apply enhancement to the Dio instance
  void enhance(Dio dio, dynamic config);

  /// Enhancement name for debugging
  String get name;
}

/// Unified factory for creating Dio clients across all providers
///
/// This factory eliminates code duplication by providing a consistent
/// approach to Dio client creation while allowing provider-specific
/// customizations through the strategy pattern.
class DioClientFactory {
  /// Create a configured Dio client using provider strategy
  ///
  /// Priority order:
  /// 1. Custom Dio client (if provided via extensions)
  /// 2. HTTP configuration with provider strategy
  /// 3. Provider defaults
  static Dio create({
    required ProviderDioStrategy strategy,
    required dynamic config,
  }) {
    // Extract custom Dio from config extensions
    final customDio = _extractCustomDio(config);

    if (customDio != null) {
      // Use custom Dio with provider-specific enhancements
      return _enhanceCustomDio(customDio, strategy, config);
    } else {
      // Create new Dio with unified configuration
      return _createConfiguredDio(strategy, config);
    }
  }

  /// Extract custom Dio from config extensions
  static Dio? _extractCustomDio(dynamic config) {
    if (config.originalConfig != null) {
      return config.originalConfig!.getExtension<Dio>('customDio');
    }
    return null;
  }

  /// Enhance custom Dio with provider-specific requirements
  static Dio _enhanceCustomDio(
    Dio customDio,
    ProviderDioStrategy strategy,
    dynamic config,
  ) {
    // Ensure base URL is set if not already configured
    if (customDio.options.baseUrl.isEmpty) {
      customDio.options.baseUrl = strategy.getBaseUrl(config);
    }

    // Merge essential headers (user's headers take precedence)
    final essentialHeaders = strategy.buildHeaders(config);
    for (final entry in essentialHeaders.entries) {
      customDio.options.headers.putIfAbsent(entry.key, () => entry.value);
    }

    // Apply provider-specific enhancements
    final enhancers = strategy.getEnhancers(config);
    for (final enhancer in enhancers) {
      enhancer.enhance(customDio, config);
    }

    return customDio;
  }

  /// Create new configured Dio instance
  static Dio _createConfiguredDio(
    ProviderDioStrategy strategy,
    dynamic config,
  ) {
    final originalConfig = config.originalConfig ?? _createFallbackConfig(strategy, config);

    final dio = BaseHttpProvider.createConfiguredDio(
      baseUrl: strategy.getBaseUrl(config),
      headers: strategy.buildHeaders(config),
      config: originalConfig,
      timeout: strategy.getTimeout(config),
    );

    // Apply provider-specific enhancements
    final enhancers = strategy.getEnhancers(config);
    for (final enhancer in enhancers) {
      enhancer.enhance(dio, config);
    }

    return dio;
  }

  /// Create minimal fallback config when originalConfig is not available
  static LLMConfig _createFallbackConfig(
    ProviderDioStrategy strategy,
    dynamic config,
  ) {
    return LLMConfig(
      baseUrl: strategy.getBaseUrl(config),
      model: config.model,
      apiKey: config.apiKey,
      timeout: strategy.getTimeout(config),
    );
  }
}

/// Base implementation for common provider strategy patterns
abstract class BaseProviderDioStrategy implements ProviderDioStrategy {
  @override
  String getBaseUrl(dynamic config) => config.baseUrl;

  @override
  Duration? getTimeout(dynamic config) => config.timeout;

  @override
  List<DioEnhancer> getEnhancers(dynamic config) => [];
}

/// Interceptor-based enhancer for adding custom interceptors
class InterceptorEnhancer implements DioEnhancer {
  final Interceptor interceptor;
  final String _name;

  InterceptorEnhancer(this.interceptor, this._name);

  @override
  void enhance(Dio dio, dynamic config) {
    dio.interceptors.add(interceptor);
  }

  @override
  String get name => _name;
}

/// Header-based enhancer for dynamic header modification
class HeaderEnhancer implements DioEnhancer {
  final Map<String, String> Function(dynamic config) headerBuilder;
  final String _name;

  HeaderEnhancer(this.headerBuilder, this._name);

  @override
  void enhance(Dio dio, dynamic config) {
    final headers = headerBuilder(config);
    dio.options.headers.addAll(headers);
  }

  @override
  String get name => _name;
}
