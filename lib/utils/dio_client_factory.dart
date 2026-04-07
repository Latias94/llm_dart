import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../core/config.dart';
import '../src/config/legacy_config_extensions.dart';

export 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        BaseProviderDioStrategy,
        DioClientOverrides,
        DioEnhancer,
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
    if (config is DioClientOverrides) {
      return config;
    }

    final originalConfig = config.originalConfig as LLMConfig?;
    if (originalConfig == null) {
      return null;
    }

    return _LegacyConfigDioClientOverrides(
      originalConfig,
      fallbackTimeout: strategy.getTimeout(config),
    );
  }
}

final class _LegacyConfigDioClientOverrides implements DioClientOverrides {
  final LLMConfig _config;
  final Duration? _fallbackTimeout;

  const _LegacyConfigDioClientOverrides(
    this._config, {
    Duration? fallbackTimeout,
  }) : _fallbackTimeout = fallbackTimeout;

  @override
  bool get bypassSslVerification => _config.legacyBypassSslVerification;

  @override
  String? get certificatePath => _config.legacySslCertificatePath;

  @override
  Duration? get connectionTimeout => _config.legacyConnectionTimeout;

  @override
  Dio? get customDio {
    final customTransport = _config.legacyTransportClient;
    if (customTransport case DioTransportClient(:final dio)) {
      return dio;
    }

    return _config.legacyCustomDio;
  }

  @override
  Map<String, String> get customHeaders => _config.legacyCustomHeaders;

  @override
  bool get enableHttpLogging => _config.legacyEnableHttpLogging;

  @override
  String? get proxyUrl => _config.legacyHttpProxy;

  @override
  Duration? get receiveTimeout => _config.legacyReceiveTimeout;

  @override
  Duration? get sendTimeout => _config.legacySendTimeout;

  @override
  Duration? get timeout => _config.timeout ?? _fallbackTimeout;
}
