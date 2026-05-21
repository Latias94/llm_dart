import '../chat_completions/openai_chat_completions_language_model_route_adapter.dart';
import '../provider/openai_family_profile.dart';
import '../provider/openai_family_route_policy.dart';
import '../responses/openai_responses_language_model_route_adapter.dart';
import 'openai_language_model_route_adapter.dart';

final class OpenAILanguageModelRouteAdapters {
  final OpenAILanguageModelRouteAdapter responses;
  final OpenAILanguageModelRouteAdapter chatCompletions;

  const OpenAILanguageModelRouteAdapters({
    this.responses = const OpenAIResponsesLanguageModelRouteAdapter(),
    required this.chatCompletions,
  });

  factory OpenAILanguageModelRouteAdapters.forProfile(
    OpenAIFamilyProfile profile,
  ) {
    return OpenAILanguageModelRouteAdapters(
      chatCompletions:
          OpenAIChatCompletionsLanguageModelRouteAdapter.forProfile(profile),
    );
  }

  OpenAILanguageModelRouteAdapter resolve(OpenAIRequestRoute route) {
    return switch (route) {
      OpenAIRequestRoute.responses => responses,
      OpenAIRequestRoute.chatCompletions => chatCompletions,
    };
  }
}
