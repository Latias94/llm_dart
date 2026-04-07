import 'package:dio/dio.dart';

import 'dio_http_client_config.dart';
import 'dio_http_client_factory.dart';

/// Transport-owned override surface for provider-specific Dio client creation.
abstract interface class DioClientOverrides {
  Dio? get customDio;
  Map<String, String> get customHeaders;
  Duration? get timeout;
  Duration? get connectionTimeout;
  Duration? get receiveTimeout;
  Duration? get sendTimeout;
  bool get enableHttpLogging;
  String? get proxyUrl;
  bool get bypassSslVerification;
  String? get certificatePath;
}

/// Strategy interface for provider-specific Dio configuration.
abstract class ProviderDioStrategy {
  /// Provider name for logging and debugging.
  String get providerName;

  /// Build provider-specific HTTP headers.
  Map<String, String> buildHeaders(dynamic config);

  /// Get list of provider-specific enhancers.
  List<DioEnhancer> getEnhancers(dynamic config);

  /// Get base URL for the provider.
  String getBaseUrl(dynamic config);

  /// Get timeout configuration.
  Duration? getTimeout(dynamic config);
}

/// Interface for composable Dio enhancements.
abstract class DioEnhancer {
  /// Apply enhancement to the Dio instance.
  void enhance(Dio dio, dynamic config);

  /// Enhancement name for debugging.
  String get name;
}

/// Base implementation for common provider strategy patterns.
abstract class BaseProviderDioStrategy implements ProviderDioStrategy {
  @override
  String getBaseUrl(dynamic config) => config.baseUrl;

  @override
  Duration? getTimeout(dynamic config) => config.timeout;

  @override
  List<DioEnhancer> getEnhancers(dynamic config) => [];
}

/// Interceptor-based enhancer for adding custom interceptors.
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

/// Header-based enhancer for dynamic header modification.
class HeaderEnhancer implements DioEnhancer {
  final Map<String, String> Function(dynamic config) headerBuilder;
  final String _name;

  HeaderEnhancer(this.headerBuilder, this._name);

  @override
  void enhance(Dio dio, dynamic config) {
    dio.options.headers.addAll(headerBuilder(config));
  }

  @override
  String get name => _name;
}

/// Transport-owned Dio client factory for provider implementations.
class ProviderDioClientFactory {
  /// Create a configured Dio client using provider strategy and overrides.
  static Dio create({
    required ProviderDioStrategy strategy,
    required dynamic config,
    DioClientOverrides? overrides,
  }) {
    final effectiveOverrides =
        overrides ?? (config is DioClientOverrides ? config : null);
    final customDio = effectiveOverrides?.customDio;

    if (customDio != null) {
      return _enhanceCustomDio(
        customDio,
        strategy: strategy,
        config: config,
      );
    }

    return _createConfiguredDio(
      strategy: strategy,
      config: config,
      overrides: effectiveOverrides,
    );
  }

  static Dio _enhanceCustomDio(
    Dio customDio, {
    required ProviderDioStrategy strategy,
    required dynamic config,
  }) {
    if (customDio.options.baseUrl.isEmpty) {
      customDio.options.baseUrl = strategy.getBaseUrl(config);
    }

    final essentialHeaders = strategy.buildHeaders(config);
    for (final entry in essentialHeaders.entries) {
      customDio.options.headers.putIfAbsent(entry.key, () => entry.value);
    }

    for (final enhancer in strategy.getEnhancers(config)) {
      enhancer.enhance(customDio, config);
    }

    return customDio;
  }

  static Dio _createConfiguredDio({
    required ProviderDioStrategy strategy,
    required dynamic config,
    required DioClientOverrides? overrides,
  }) {
    final dio = DioHttpClientFactory.createConfiguredDio(
      config: DioHttpClientConfig(
        baseUrl: strategy.getBaseUrl(config),
        defaultHeaders: strategy.buildHeaders(config),
        customHeaders: overrides?.customHeaders ?? const <String, String>{},
        timeout: overrides?.timeout ?? strategy.getTimeout(config),
        connectionTimeout: overrides?.connectionTimeout,
        receiveTimeout: overrides?.receiveTimeout,
        sendTimeout: overrides?.sendTimeout,
        enableLogging: overrides?.enableHttpLogging ?? false,
        proxyUrl: overrides?.proxyUrl,
        bypassSslVerification: overrides?.bypassSslVerification ?? false,
        certificatePath: overrides?.certificatePath,
      ),
    );

    for (final enhancer in strategy.getEnhancers(config)) {
      enhancer.enhance(dio, config);
    }

    return dio;
  }
}
