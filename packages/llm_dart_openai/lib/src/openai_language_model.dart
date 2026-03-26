import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_options.dart';

final class OpenAILanguageModel implements LanguageModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIChatModelSettings settings;

  @override
  final String modelId;

  OpenAILanguageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    this.baseUrl = 'https://api.openai.com/v1',
    this.settings = const OpenAIChatModelSettings(),
  });

  @override
  String get providerId => profile.providerId;

  Uri get responsesUri => Uri.parse('$baseUrl/responses');

  Map<String, String> get defaultHeaders => profile.buildHeaders(
        apiKey: apiKey,
        extraHeaders: {
          if (settings.organization case final organization?)
            'openai-organization': organization,
          if (settings.project case final project?) 'openai-project': project,
          ...settings.headers,
        },
      );

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) {
    throw UnimplementedError(
      'OpenAI generate() has not been migrated to the new architecture yet.',
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) {
    throw UnimplementedError(
      'OpenAI stream() has not been migrated to the new architecture yet.',
    );
  }
}
