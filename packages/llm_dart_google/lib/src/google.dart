import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_embedding_model.dart';
import 'google_language_model.dart';
import 'google_options.dart';

final class Google {
  static const String defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final String apiKey;
  final String baseUrl;
  final TransportClient transport;

  Google({
    required this.apiKey,
    TransportClient? transport,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        transport = transport ?? DioTransportClient();

  GoogleLanguageModel chatModel(
    String modelId, {
    GoogleChatModelSettings settings = const GoogleChatModelSettings(),
  }) {
    return GoogleLanguageModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  GoogleEmbeddingModel embeddingModel(
    String modelId, {
    GoogleEmbeddingModelSettings settings =
        const GoogleEmbeddingModelSettings(),
  }) {
    return GoogleEmbeddingModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }
}
