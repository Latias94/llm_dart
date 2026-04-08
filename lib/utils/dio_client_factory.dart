import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

export 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        BaseProviderDioStrategy,
        DioClientOverrides,
        DioEnhancer,
        HasDioClientOverrides,
        HeaderEnhancer,
        InterceptorEnhancer,
        ProviderDioStrategy;

/// Compatibility wrapper around the transport-owned provider Dio client factory.
class DioClientFactory {
  /// Create a configured Dio client using provider strategy.
  static Dio create({
    required ProviderDioStrategy strategy,
    required dynamic config,
  }) {
    return ProviderDioClientFactory.create(
      strategy: strategy,
      config: config,
      overrides: _resolveOverrides(strategy, config),
    );
  }

  static DioClientOverrides? _resolveOverrides(
    ProviderDioStrategy strategy,
    dynamic config,
  ) {
    if (config is HasDioClientOverrides) {
      final overrides = config.dioOverrides;
      if (overrides != null) {
        return overrides;
      }
    }

    if (config is DioClientOverrides) {
      return config;
    }
    return null;
  }
}
