import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, DioTransportClient, ImmutableDioClientOverrides;

import '../../../core/config.dart';
import '../../../providers/elevenlabs/config.dart';
import '../../../providers/ollama/config.dart';
import '../../config/legacy_config_extensions.dart';

/// Projects legacy HTTP-related `LLMConfig` settings into transport-owned
/// provider Dio overrides for compatibility-era community providers.
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

/// Adapts a legacy root `LLMConfig` into an Ollama provider config.
OllamaConfig createLegacyOllamaConfig(LLMConfig config) {
  return OllamaConfig(
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    jsonSchema: config.legacyJsonSchema,
    numCtx: config.getExtension<int>(LegacyExtensionKeys.numCtx),
    numGpu: config.getExtension<int>(LegacyExtensionKeys.numGpu),
    numThread: config.getExtension<int>(LegacyExtensionKeys.numThread),
    numa: config.getExtension<bool>(LegacyExtensionKeys.numa),
    numBatch: config.getExtension<int>(LegacyExtensionKeys.numBatch),
    keepAlive: config.getExtension<String>(LegacyExtensionKeys.keepAlive),
    raw: config.getExtension<bool>(LegacyExtensionKeys.raw),
    reasoning: config.getExtension<bool>(LegacyExtensionKeys.reasoning),
  );
}

/// Adapts a legacy root `LLMConfig` into an ElevenLabs provider config.
ElevenLabsConfig createLegacyElevenLabsConfig(LLMConfig config) {
  return ElevenLabsConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    voiceId: config.getExtension<String>(LegacyExtensionKeys.voiceId),
    stability: config.getExtension<double>(LegacyExtensionKeys.stability),
    similarityBoost:
        config.getExtension<double>(LegacyExtensionKeys.similarityBoost),
    style: config.getExtension<double>(LegacyExtensionKeys.style),
    useSpeakerBoost:
        config.getExtension<bool>(LegacyExtensionKeys.useSpeakerBoost),
  );
}
