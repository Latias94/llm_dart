import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, DioTransportClient, ImmutableDioClientOverrides;

import '../../../core/config.dart';
import '../config/legacy_config_extensions.dart';

/// Projects legacy HTTP-related `LLMConfig` settings into transport-owned
/// provider Dio overrides for compatibility-era provider adapters.
DioClientOverrides? createLegacyDioClientOverrides(LLMConfig config) {
  final customTransport = config.legacyTransportClient;
  final customDio = switch (customTransport) {
    DioTransportClient(:final dio) => dio,
    _ => config.legacyCustomDio,
  };

  if (customDio == null &&
      config.legacyCustomHeaders.isEmpty &&
      !config.legacyEnableHttpLogging &&
      config.legacyHttpProxy == null &&
      !config.legacyBypassSslVerification &&
      config.legacySslCertificatePath == null &&
      config.legacyConnectionTimeout == null &&
      config.legacyReceiveTimeout == null &&
      config.legacySendTimeout == null) {
    return null;
  }

  return ImmutableDioClientOverrides(
    customDio: customDio,
    customHeaders: config.legacyCustomHeaders,
    enableHttpLogging: config.legacyEnableHttpLogging,
    proxyUrl: config.legacyHttpProxy,
    bypassSslVerification: config.legacyBypassSslVerification,
    certificatePath: config.legacySslCertificatePath,
    connectionTimeout: config.legacyConnectionTimeout,
    receiveTimeout: config.legacyReceiveTimeout,
    sendTimeout: config.legacySendTimeout,
    timeout: config.timeout,
  );
}
