import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../defaults.dart';
import '../google_vertex_factory.dart';
import 'package:llm_dart_google/google.dart';

class VertexProviderSettings {
  final Object? apiKey;
  final Object? baseUrl;
  final Map<String, String>? headers;
  final Duration? timeout;

  /// Optional provider constructor override (useful for tests).
  final GoogleProvider Function(GoogleConfig config)? providerFactory;

  const VertexProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
    this.providerFactory,
  });
}

/// Google Vertex AI provider factory (AI SDK v3 style, express mode).
///
/// This package currently targets express mode (API key authentication), aligned
/// with upstream `@ai-sdk/google-vertex` when an API key is provided.
class VertexProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final VertexProviderSettings settings;

  const VertexProviderV3(this.settings);

  GoogleProvider call(String modelId) =>
      languageModel(modelId) as GoogleProvider;

  String _loadVertexApiKey() {
    final provided = settings.apiKey;
    if (provided is String) return provided;
    if (provided != null) {
      throw const LoadApiKeyError(
        message: 'Google Vertex API key must be a string.',
      );
    }

    final envKey = loadOptionalSetting(
          settingValue: null,
          environmentVariableName: 'GOOGLE_VERTEX_API_KEY',
        ) ??
        loadOptionalSetting(
          settingValue: null,
          environmentVariableName: 'VERTEX_API_KEY',
        );

    if (envKey != null && envKey.isNotEmpty) return envKey;

    // Reuse the standard error message semantics.
    return loadApiKey(
      apiKey: null,
      apiKeyParameterName: 'apiKey',
      environmentVariableName: 'GOOGLE_VERTEX_API_KEY',
      description: 'Google Vertex',
    );
  }

  GoogleConfig _configForModel(String modelId) {
    final apiKey = _loadVertexApiKey();

    final rawBaseUrl = settings.baseUrl is String
        ? (settings.baseUrl as String).trim()
        : null;
    final baseUrl = withoutTrailingSlash(
          rawBaseUrl != null && rawBaseUrl.isNotEmpty ? rawBaseUrl : null,
        ) ??
        withoutTrailingSlash(googleVertexBaseUrl)!;

    return GoogleConfig(
      providerOptionsName: vertexProviderId,
      providerId: vertexProviderId,
      providerOptionsFallbackIds: const ['google-vertex', 'google'],
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      extraHeaders: settings.headers,
      timeout: settings.timeout,
    );
  }

  GoogleProvider _newProvider(GoogleConfig config) {
    final factory = settings.providerFactory;
    if (factory == null) return GoogleProvider(config);
    return factory(config);
  }

  @override
  ChatCapability languageModel(String modelId) => _newProvider(
        _configForModel(modelId),
      );

  @override
  EmbeddingCapability embeddingModel(String modelId) => _newProvider(
        _configForModel(modelId),
      );

  @override
  ImageGenerationCapability imageModel(String modelId) => _newProvider(
        _configForModel(modelId),
      );

  @override
  ExperimentalVideoGenerationCapability videoModel(String modelId) =>
      _newProvider(
        _configForModel(modelId),
      );
}

