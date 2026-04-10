import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../core/config.dart';
import 'legacy_config_extensions.dart';

/// Compatibility mixin that exposes legacy `LLMConfig` HTTP overrides through
/// the transport-owned `DioClientOverrides` interface.
mixin LegacyDioClientOverrides implements DioClientOverrides {
  LLMConfig? get originalConfig;

  @override
  Duration? get timeout;

  @override
  bool get bypassSslVerification =>
      originalConfig?.legacyBypassSslVerification ?? false;

  @override
  String? get certificatePath => originalConfig?.legacySslCertificatePath;

  @override
  Duration? get connectionTimeout => originalConfig?.legacyConnectionTimeout;

  @override
  Dio? get customDio {
    final config = originalConfig;
    if (config == null) {
      return null;
    }

    final customTransport = config.legacyTransportClient;
    if (customTransport case DioTransportClient(:final dio)) {
      return dio;
    }

    return config.legacyCustomDio;
  }

  @override
  Map<String, String> get customHeaders =>
      originalConfig?.legacyCustomHeaders ?? const <String, String>{};

  @override
  bool get enableHttpLogging =>
      originalConfig?.legacyEnableHttpLogging ?? false;

  @override
  String? get proxyUrl => originalConfig?.legacyHttpProxy;

  @override
  Duration? get receiveTimeout => originalConfig?.legacyReceiveTimeout;

  @override
  Duration? get sendTimeout => originalConfig?.legacySendTimeout;
}
