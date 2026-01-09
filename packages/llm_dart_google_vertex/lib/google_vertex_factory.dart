library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'defaults.dart';

const String googleVertexProviderId = 'google-vertex';

void registerGoogleVertex({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(googleVertexProviderId)) {
    return;
  }
  final factory = GoogleVertexProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

class GoogleVertexProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => googleVertexProviderId;

  @override
  String get displayName => 'Google Vertex';

  @override
  String get description =>
      'Google Vertex AI (Gemini) provider (express mode, API key).';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.reasoning,
        LLMCapability.vision,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<GoogleConfig>(
      config,
      () => _transformConfig(config),
      (googleConfig) => GoogleProvider(googleConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': googleVertexBaseUrl,
      'model': googleVertexDefaultModel,
    };
  }

  GoogleConfig _transformConfig(LLMConfig config) {
    // Derive config from the unified LLMConfig, but:
    // - Read provider options from this provider id (google-vertex)
    // - Emit provider metadata under `vertex` for AI SDK parity.
    final baseUrl = _ensureTrailingSlash(config.baseUrl);
    return GoogleConfig.fromLLMConfig(
      config,
      providerId: googleVertexProviderId,
      providerOptionsName: 'vertex',
    ).copyWith(
      baseUrl: baseUrl,
      model: config.model.isEmpty ? googleVertexDefaultModel : config.model,
    );
  }

  static String _ensureTrailingSlash(String url) {
    if (url.isEmpty) return googleVertexBaseUrl;
    return url.endsWith('/') ? url : '$url/';
  }
}
