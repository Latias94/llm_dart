import 'package:dio/dio.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../core/config.dart';
import '../../core/web_search.dart';
import '../../models/tool_models.dart';

export 'legacy_config_keys.dart';
import 'legacy_config_keys.dart';

/// Typed accessors for the legacy compatibility extension map.
///
/// This is a transitional layer for the old root-package API. It reduces
/// repeated string-key lookups without widening `LLMConfig` itself with more
/// provider-specific surface area.
extension LegacyConfigAccessors on LLMConfig {
  String? get legacyReasoningEffortValue =>
      getExtension<String>(LegacyExtensionKeys.reasoningEffort);

  StructuredOutputFormat? get legacyJsonSchema =>
      getExtension<StructuredOutputFormat>(LegacyExtensionKeys.jsonSchema);

  String? get legacyVoice => getExtension<String>(LegacyExtensionKeys.voice);

  String? get legacyEmbeddingEncodingFormat =>
      getExtension<String>(LegacyExtensionKeys.embeddingEncodingFormat);

  int? get legacyEmbeddingDimensions =>
      getExtension<int>(LegacyExtensionKeys.embeddingDimensions);

  bool get legacyWebSearchEnabled =>
      getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true;

  WebSearchConfig? get legacyWebSearchConfig =>
      getExtension<WebSearchConfig>(LegacyExtensionKeys.webSearchConfig);

  bool get hasLegacyWebSearch =>
      legacyWebSearchEnabled || legacyWebSearchConfig != null;

  Duration? get legacyConnectionTimeout =>
      getExtension<Duration>(LegacyExtensionKeys.connectionTimeout);

  Duration? get legacyReceiveTimeout =>
      getExtension<Duration>(LegacyExtensionKeys.receiveTimeout);

  Duration? get legacySendTimeout =>
      getExtension<Duration>(LegacyExtensionKeys.sendTimeout);

  Map<String, String> get legacyCustomHeaders =>
      getExtension<Map<String, String>>(LegacyExtensionKeys.customHeaders) ??
      const <String, String>{};

  bool get legacyEnableHttpLogging =>
      getExtension<bool>(LegacyExtensionKeys.enableHttpLogging) ?? false;

  bool get legacyBypassSslVerification =>
      getExtension<bool>(LegacyExtensionKeys.bypassSslVerification) ?? false;

  String? get legacyHttpProxy =>
      getExtension<String>(LegacyExtensionKeys.httpProxy);

  String? get legacySslCertificatePath =>
      getExtension<String>(LegacyExtensionKeys.sslCertificate);

  TransportClient? get legacyTransportClient =>
      getExtension<TransportClient>(LegacyExtensionKeys.customTransportClient);

  Dio? get legacyCustomDio => getExtension<Dio>(LegacyExtensionKeys.customDio);
}
