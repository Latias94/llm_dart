import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../../core/config.dart';
import '../config/legacy_config_extensions.dart';

/// Builds transport-owned HTTP client config from legacy root `LLMConfig`.
DioHttpClientConfig createLegacyHttpClientConfig({
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
