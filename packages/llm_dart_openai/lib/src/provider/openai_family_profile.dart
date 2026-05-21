import '../chat_completions/openai_chat_completions_deepseek_policy.dart';
import '../chat_completions/openai_chat_completions_request_policy.dart';
import 'deepseek_option_resolver.dart';
import 'openai_family_capability_core.dart';
import 'openai_family_option_resolver_base.dart';
import 'openai_family_route_policy.dart';
import 'openai_family_common_option_resolver.dart';
import 'openrouter_capability_policy.dart';
import 'openrouter_option_resolver.dart';
import 'deepseek_capability_policy.dart';
import 'xai_capability_policy.dart';
import 'xai_option_resolver.dart';

abstract interface class OpenAIFamilyProfile {
  String get providerId;

  String get defaultBaseUrl;

  OpenAIFamilyRoutePolicy get routePolicy;

  OpenAIFamilyOptionResolver get optionResolver;

  OpenAIFamilyCapabilityPolicy get capabilityPolicy;

  OpenAIChatCompletionsRequestPolicy get chatCompletionsRequestPolicy;

  bool get supportsOpenAIToolOptions;

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

  const _BearerAuthOpenAIFamilyProfile({
    required this.providerId,
    required this.defaultBaseUrl,
  });

  @override
  OpenAIFamilyRoutePolicy get routePolicy =>
      const OpenAIChatCompletionsOnlyRoutePolicy();

  @override
  OpenAIFamilyOptionResolver get optionResolver =>
      const CommonOpenAIOptionResolver();

  @override
  OpenAIFamilyCapabilityPolicy get capabilityPolicy =>
      const CompatibleOpenAICapabilityPolicy();

  @override
  OpenAIChatCompletionsRequestPolicy get chatCompletionsRequestPolicy =>
      const CompatibleChatCompletionsRequestPolicy();

  @override
  bool get supportsOpenAIToolOptions => false;

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
  });

  @override
  OpenAIFamilyRoutePolicy get routePolicy =>
      const OpenAIResponsesFirstRoutePolicy();

  @override
  OpenAIFamilyCapabilityPolicy get capabilityPolicy =>
      const OpenAICapabilityPolicy();

  @override
  OpenAIChatCompletionsRequestPolicy get chatCompletionsRequestPolicy =>
      const OpenAIChatCompletionsOpenAIRequestPolicy();

  @override
  bool get supportsOpenAIToolOptions => true;
}

final class OpenAICompatibleProfile extends _BearerAuthOpenAIFamilyProfile {
  const OpenAICompatibleProfile({
    required super.providerId,
    required super.defaultBaseUrl,
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
        );

  @override
  OpenAIFamilyOptionResolver get optionResolver =>
      const OpenRouterOptionResolver();

  @override
  OpenAIFamilyCapabilityPolicy get capabilityPolicy =>
      const OpenRouterCapabilityPolicy();

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
        );

  @override
  OpenAIFamilyOptionResolver get optionResolver =>
      const DeepSeekOptionResolver();

  @override
  OpenAIFamilyCapabilityPolicy get capabilityPolicy =>
      const DeepSeekCapabilityPolicy();

  @override
  OpenAIChatCompletionsRequestPolicy get chatCompletionsRequestPolicy =>
      const DeepSeekChatCompletionsRequestPolicy();
}

final class GroqProfile extends _BearerAuthOpenAIFamilyProfile {
  const GroqProfile({
    super.defaultBaseUrl = 'https://api.groq.com/openai/v1',
  }) : super(
          providerId: 'groq',
        );
}

final class XAIProfile extends _BearerAuthOpenAIFamilyProfile {
  const XAIProfile({
    super.defaultBaseUrl = 'https://api.x.ai/v1',
  }) : super(
          providerId: 'xai',
        );

  @override
  OpenAIFamilyOptionResolver get optionResolver => const XAIOptionResolver();

  @override
  OpenAIFamilyCapabilityPolicy get capabilityPolicy =>
      const XAICapabilityPolicy();
}

final class PhindProfile extends _BearerAuthOpenAIFamilyProfile {
  const PhindProfile({
    super.defaultBaseUrl = 'https://api.phind.com/v1',
  }) : super(
          providerId: 'phind',
        );
}
