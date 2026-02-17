library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'defaults.dart';

/// Canonical provider id for Google Vertex (AI SDK v6 parity).
const String vertexProviderId = 'vertex';

void registerGoogleVertex({bool replace = false}) {
  final vertexRegistered = LLMProviderRegistry.isRegistered(vertexProviderId);
  final legacyRegistered = LLMProviderRegistry.isRegistered('google-vertex');

  if (!replace && vertexRegistered && legacyRegistered) {
    return;
  }

  final vertexFactory = VertexProviderFactory();
  final legacyFactory = GoogleVertexProviderFactory();

  if (replace) {
    LLMProviderRegistry.registerOrReplace(vertexFactory);
    LLMProviderRegistry.registerOrReplace(legacyFactory);
    return;
  }

  if (!vertexRegistered) {
    LLMProviderRegistry.register(vertexFactory);
  }
  if (!legacyRegistered) {
    LLMProviderRegistry.register(legacyFactory);
  }
}

class VertexProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => vertexProviderId;

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
    // AI SDK parity: `@ai-sdk/google-vertex` uses `vertex` as the key for both
    // providerMetadata output and providerOptions input. We still accept
    // `google-vertex` (legacy) and `google` (AI SDK <=5) as fallbacks.
    final baseUrl = _ensureTrailingSlash(config.baseUrl);
    return GoogleConfig.fromLLMConfig(
      config,
      providerId: vertexProviderId,
      providerOptionsName: vertexProviderId,
      providerOptionsFallbackIds: const [
        'google-vertex',
        'google',
      ],
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

/// Back-compat alias factory for users still using providerId `google-vertex`.
class GoogleVertexProviderFactory extends VertexProviderFactory {
  @override
  String get providerId => 'google-vertex';
}
