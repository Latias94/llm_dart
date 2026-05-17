abstract interface class OpenAIFamilyProfile {
  String get providerId;

  String get defaultBaseUrl;

  bool get supportsResponsesApi;

  Map<String, String> buildHeaders({
    required String apiKey,
    Map<String, String> extraHeaders = const {},
  });
}

enum OpenAIFamilyModelFacet {
  language,
  embedding,
  image,
  speech,
  transcription,
}

final class OpenAIFamilyModelFacetSupport {
  static const openAI = OpenAIFamilyModelFacetSupport(
    language: true,
    embedding: true,
    image: true,
    speech: true,
    transcription: true,
  );

  static const languageOnly = OpenAIFamilyModelFacetSupport(
    language: true,
  );

  final bool language;
  final bool embedding;
  final bool image;
  final bool speech;
  final bool transcription;

  const OpenAIFamilyModelFacetSupport({
    required this.language,
    this.embedding = false,
    this.image = false,
    this.speech = false,
    this.transcription = false,
  });

  bool supports(OpenAIFamilyModelFacet facet) {
    return switch (facet) {
      OpenAIFamilyModelFacet.language => language,
      OpenAIFamilyModelFacet.embedding => embedding,
      OpenAIFamilyModelFacet.image => image,
      OpenAIFamilyModelFacet.speech => speech,
      OpenAIFamilyModelFacet.transcription => transcription,
    };
  }
}

OpenAIFamilyModelFacetSupport modelFacetSupportForOpenAIFamilyProfile(
  OpenAIFamilyProfile profile,
) {
  return switch (profile) {
    OpenAIProfile() => OpenAIFamilyModelFacetSupport.openAI,
    _ => OpenAIFamilyModelFacetSupport.languageOnly,
  };
}

class _BearerAuthOpenAIFamilyProfile implements OpenAIFamilyProfile {
  @override
  final String providerId;

  @override
  final String defaultBaseUrl;

  @override
  final bool supportsResponsesApi;

  const _BearerAuthOpenAIFamilyProfile({
    required this.providerId,
    required this.defaultBaseUrl,
    required this.supportsResponsesApi,
  });

  @override
  Map<String, String> buildHeaders({
    required String apiKey,
    Map<String, String> extraHeaders = const {},
  }) {
    return <String, String>{
      'authorization': 'Bearer $apiKey',
      ...extraHeaders,
    };
  }
}

final class OpenAIProfile extends _BearerAuthOpenAIFamilyProfile {
  const OpenAIProfile({
    super.providerId = 'openai',
    super.defaultBaseUrl = 'https://api.openai.com/v1',
    super.supportsResponsesApi = true,
  });
}

final class OpenRouterProfile extends _BearerAuthOpenAIFamilyProfile {
  final String? appReferer;
  final String? appTitle;

  const OpenRouterProfile({
    this.appReferer,
    this.appTitle,
    super.defaultBaseUrl = 'https://openrouter.ai/api/v1',
  }) : super(
          providerId: 'openrouter',
          supportsResponsesApi: false,
        );

  @override
  Map<String, String> buildHeaders({
    required String apiKey,
    Map<String, String> extraHeaders = const {},
  }) {
    return <String, String>{
      'authorization': 'Bearer $apiKey',
      if (appReferer != null) 'HTTP-Referer': appReferer!,
      if (appTitle != null) 'X-OpenRouter-Title': appTitle!,
      ...extraHeaders,
    };
  }
}

final class DeepSeekProfile extends _BearerAuthOpenAIFamilyProfile {
  const DeepSeekProfile({
    super.defaultBaseUrl = 'https://api.deepseek.com/v1',
  }) : super(
          providerId: 'deepseek',
          supportsResponsesApi: false,
        );
}

final class GroqProfile extends _BearerAuthOpenAIFamilyProfile {
  const GroqProfile({
    super.defaultBaseUrl = 'https://api.groq.com/openai/v1',
  }) : super(
          providerId: 'groq',
          supportsResponsesApi: false,
        );
}

final class XAIProfile extends _BearerAuthOpenAIFamilyProfile {
  const XAIProfile({
    super.defaultBaseUrl = 'https://api.x.ai/v1',
  }) : super(
          providerId: 'xai',
          supportsResponsesApi: false,
        );
}

final class PhindProfile extends _BearerAuthOpenAIFamilyProfile {
  const PhindProfile({
    super.defaultBaseUrl = 'https://api.phind.com/v1',
  }) : super(
          providerId: 'phind',
          supportsResponsesApi: false,
        );
}
