import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_embedding_model.dart';
import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_assistants.dart';
import 'openai_files.dart';
import 'openai_image_model.dart';
import 'openai_language_model.dart';
import 'openai_moderation.dart';
import 'openai_options.dart';
import 'openai_responses_lifecycle.dart';
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

final class OpenAI
    implements
        ProviderModelFacetSupport,
        LanguageModelProvider,
        EmbeddingModelProvider,
        ImageModelProvider,
        SpeechModelProvider,
        TranscriptionModelProvider {
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
        baseUrl = normalizeOpenAIFamilyBaseUrl(
          baseUrl,
          profile ?? const OpenAIProfile(),
        ),
        transport = transport ?? DioTransportClient();

  @override
  String get providerId => profile.providerId;

  OpenAIFamilyModelFacetSupport get modelFacetSupport =>
      modelFacetSupportForOpenAIFamilyProfile(profile);

  @override
  bool get supportsLanguageModels => modelFacetSupport.language;

  @override
  bool get supportsEmbeddingModels => modelFacetSupport.embedding;

  @override
  bool get supportsImageModels => modelFacetSupport.image;

  @override
  bool get supportsSpeechModels => modelFacetSupport.speech;

  @override
  bool get supportsTranscriptionModels => modelFacetSupport.transcription;

  @override
  OpenAILanguageModel languageModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAIChatModelSettings(),
  }) {
    return chatModel(modelId, settings: settings);
  }

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

  @override
  OpenAIEmbeddingModel embeddingModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAIEmbeddingModelSettings(),
  }) {
    _requireModelFacet(OpenAIFamilyModelFacet.embedding);
    return OpenAIEmbeddingModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  @override
  OpenAIImageModel imageModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAIImageModelSettings(),
  }) {
    _requireModelFacet(OpenAIFamilyModelFacet.image);
    return OpenAIImageModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  @override
  OpenAISpeechModel speechModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAISpeechModelSettings(),
  }) {
    _requireModelFacet(OpenAIFamilyModelFacet.speech);
    return OpenAISpeechModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  @override
  OpenAITranscriptionModel transcriptionModel(
    String modelId, {
    ProviderModelOptions settings = const OpenAITranscriptionModelSettings(),
  }) {
    _requireModelFacet(OpenAIFamilyModelFacet.transcription);
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

  OpenAIAssistantsClient assistants({
    OpenAIAssistantsSettings settings = const OpenAIAssistantsSettings(),
  }) {
    return OpenAIAssistantsClient(
      apiKey: apiKey,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  OpenAIResponsesLifecycleClient responsesLifecycle({
    OpenAIResponsesLifecycleSettings settings =
        const OpenAIResponsesLifecycleSettings(),
  }) {
    return OpenAIResponsesLifecycleClient(
      apiKey: apiKey,
      transport: transport,
      profile: profile,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  void _requireModelFacet(OpenAIFamilyModelFacet facet) {
    if (modelFacetSupport.supports(facet)) {
      return;
    }

    throw UnsupportedError(
      '${profile.providerId} does not support ${facet.name} models through '
      'the OpenAI-family facade. Use chatModel(...) or a provider-owned '
      'native surface for this profile.',
    );
  }
}
