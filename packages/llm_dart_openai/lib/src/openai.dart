import 'package:llm_dart_transport/llm_dart_transport.dart';

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
    required this.transport,
    this.baseUrl = 'https://api.openai.com/v1',
    OpenAIFamilyProfile? profile,
  }) : profile = profile ?? const OpenAIProfile();

  OpenAILanguageModel chatModel(
    String modelId, {
    OpenAIChatModelSettings settings = const OpenAIChatModelSettings(),
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
}
