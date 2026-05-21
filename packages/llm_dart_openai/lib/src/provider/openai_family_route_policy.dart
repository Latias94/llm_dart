import 'resolved_openai_chat_settings.dart';

enum OpenAIRequestRoute {
  responses,
  chatCompletions,
}

abstract interface class OpenAIFamilyRoutePolicy {
  const factory OpenAIFamilyRoutePolicy.responsesFirst() =
      OpenAIResponsesFirstRoutePolicy;

  const factory OpenAIFamilyRoutePolicy.chatCompletionsOnly() =
      OpenAIChatCompletionsOnlyRoutePolicy;

  OpenAIRequestRoute resolveLanguageModelRoute(
    ResolvedOpenAIChatModelSettings settings,
  );
}

final class OpenAIResponsesFirstRoutePolicy implements OpenAIFamilyRoutePolicy {
  const OpenAIResponsesFirstRoutePolicy();

  @override
  OpenAIRequestRoute resolveLanguageModelRoute(
    ResolvedOpenAIChatModelSettings settings,
  ) {
    return settings.common.useResponsesApi
        ? OpenAIRequestRoute.responses
        : OpenAIRequestRoute.chatCompletions;
  }
}

final class OpenAIChatCompletionsOnlyRoutePolicy
    implements OpenAIFamilyRoutePolicy {
  const OpenAIChatCompletionsOnlyRoutePolicy();

  @override
  OpenAIRequestRoute resolveLanguageModelRoute(
    ResolvedOpenAIChatModelSettings settings,
  ) {
    return OpenAIRequestRoute.chatCompletions;
  }
}
