import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_embedding_model.dart';
import 'openai_family_profile.dart';
import 'openai_language_model.dart';
import 'openai_options.dart';

final class OpenAI {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final OpenAIFamilyProfile profile;

  OpenAI({
    required this.apiKey,
    TransportClient? transport,
    String? baseUrl,
    OpenAIFamilyProfile? profile,
  })  : profile = profile ?? const OpenAIProfile(),
        baseUrl = baseUrl ?? (profile ?? const OpenAIProfile()).defaultBaseUrl,
        transport = transport ?? DioTransportClient();

  OpenAILanguageModel chatModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAIChatModelSettings(),
  }) {
    return OpenAILanguageModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  OpenAIEmbeddingModel embeddingModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAIEmbeddingModelSettings(),
  }) {
    return OpenAIEmbeddingModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }
}
