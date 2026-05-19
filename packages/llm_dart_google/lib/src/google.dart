import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_embedding_model.dart';
import 'google_image_model.dart';
import 'google_language_model.dart';
import 'google_model_settings.dart';
import 'google_speech_model.dart';

/// Creates a Google provider facade.
Google google({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return Google(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

final class Google
    implements
        LanguageModelProvider,
        EmbeddingModelProvider,
        ImageModelProvider,
        SpeechModelProvider {
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

  @override
  String get providerId => 'google';

  @override
  GoogleLanguageModel languageModel(
    String modelId, {
    GoogleChatModelSettings settings = const GoogleChatModelSettings(),
  }) {
    return chatModel(modelId, settings: settings);
  }

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

  @override
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

  @override
  GoogleImageModel imageModel(
    String modelId, {
    GoogleImageModelSettings settings = const GoogleImageModelSettings(),
  }) {
    return GoogleImageModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  @override
  GoogleSpeechModel speechModel(
    String modelId, {
    GoogleSpeechModelSettings settings = const GoogleSpeechModelSettings(),
  }) {
    return GoogleSpeechModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }
}
