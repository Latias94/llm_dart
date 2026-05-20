import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_language_model_execution.dart';
import 'openai_language_model_prepared_call.dart';
import 'openai_model_settings.dart';
import 'openai_model_describer.dart';
import 'openai_provider_support.dart';
import 'openrouter_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'openai_responses_codec.dart';

final class OpenAILanguageModel
    implements LanguageModel, CapabilityDescribedModel {
  static const OpenAIResponsesCodec _codec = OpenAIResponsesCodec();
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final ResolvedOpenAIChatModelSettings settings;
  late final OpenAIChatCompletionsCodec _chatCompletionsCodec =
      OpenAIChatCompletionsCodec.forProfile(profile);

  @override
  final String modelId;

  OpenAILanguageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAIChatModelSettings(),
  })  : settings = resolveOpenAIModelSettingsForProfile(profile, settings),
        baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile);

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    final modelSettings = settings.openRouterSearch == null
        ? settings.common
        : OpenRouterChatModelSettings(
            common: settings.common,
            search: settings.openRouterSearch,
          );

    return describeOpenAIChatModel(
      modelId,
      profile: profile,
      settings: modelSettings,
    );
  }

  Uri get responsesUri => Uri.parse('$baseUrl/responses');
  Uri get chatCompletionsUri => Uri.parse('$baseUrl/chat/completions');
  Map<String, String> get defaultHeaders => buildOpenAIDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
      );

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    final preparedCall = prepareOpenAILanguageModelCall(
      request: request,
      modelId: modelId,
      baseUrl: baseUrl,
      profile: profile,
      apiKey: apiKey,
      settings: settings,
      stream: false,
      responsesCodec: _codec,
      chatCompletionsCodec: _chatCompletionsCodec,
    );
    return sendOpenAILanguageModelGenerateCall(
      transport: transport,
      preparedCall: preparedCall,
      responsesCodec: _codec,
      chatCompletionsCodec: _chatCompletionsCodec,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
      GenerateTextRequest request) async* {
    final preparedCall = prepareOpenAILanguageModelCall(
      request: request,
      modelId: modelId,
      baseUrl: baseUrl,
      profile: profile,
      apiKey: apiKey,
      settings: settings,
      stream: true,
      responsesCodec: _codec,
      chatCompletionsCodec: _chatCompletionsCodec,
    );

    yield* sendOpenAILanguageModelStreamCall(
      transport: transport,
      preparedCall: preparedCall,
      includeRawChunks: request.options.includeRawChunks,
      responsesCodec: _codec,
      chatCompletionsCodec: _chatCompletionsCodec,
    );
  }
}
