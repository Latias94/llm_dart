import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_embedding_model.dart';
import 'openai_family_profile.dart';
import 'openai_files.dart';
import 'openai_image_model.dart';
import 'openai_language_model.dart';
import 'openai_moderation.dart';
import 'openai_options.dart';
import 'openai_speech_model.dart';
import 'openai_transcription_model.dart';

/// Creates an OpenAI provider facade.
OpenAI openai({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
  OpenAIFamilyProfile? profile,
}) {
  return OpenAI(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: profile,
  );
}

/// Creates an OpenRouter provider facade backed by the OpenAI-family adapter.
OpenAI openRouter({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
  String? appReferer,
  String? appTitle,
}) {
  return openai(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: OpenRouterProfile(
      appReferer: appReferer,
      appTitle: appTitle,
    ),
  );
}

/// Creates a DeepSeek provider facade backed by the OpenAI-family adapter.
OpenAI deepSeek({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return openai(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: const DeepSeekProfile(),
  );
}

/// Creates a Groq provider facade backed by the OpenAI-family adapter.
OpenAI groq({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return openai(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: const GroqProfile(),
  );
}

/// Creates an xAI provider facade backed by the OpenAI-family adapter.
OpenAI xai({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return openai(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: const XAIProfile(),
  );
}

/// Creates a Phind provider facade backed by the OpenAI-family adapter.
OpenAI phind({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return openai(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: const PhindProfile(),
  );
}

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

  OpenAIImageModel imageModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAIImageModelSettings(),
  }) {
    return OpenAIImageModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  OpenAISpeechModel speechModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAISpeechModelSettings(),
  }) {
    return OpenAISpeechModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  OpenAITranscriptionModel transcriptionModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAITranscriptionModelSettings(),
  }) {
    return OpenAITranscriptionModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  OpenAIModerationClient moderation({
    OpenAIModerationSettings settings = const OpenAIModerationSettings(),
  }) {
    return OpenAIModerationClient(
      apiKey: apiKey,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  OpenAIFilesClient files({
    OpenAIFilesSettings settings = const OpenAIFilesSettings(),
  }) {
    return OpenAIFilesClient(
      apiKey: apiKey,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }
}
