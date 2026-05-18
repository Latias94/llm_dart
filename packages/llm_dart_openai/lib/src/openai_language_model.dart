import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_language_model_request.dart';
import 'openai_language_model_response.dart';
import 'openai_language_model_stream.dart';
import 'openai_language_model_support.dart';
import 'openai_language_model_transport.dart';
import 'openai_model_describer.dart';
import 'openai_options.dart';
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
    final call = resolveOpenAILanguageModelCall(
      request: request,
      modelId: modelId,
      profile: profile,
      settings: settings,
    );
    final preparedRequest = encodeOpenAILanguageModelRequest(
      call: call,
      request: request,
      stream: false,
      responsesCodec: _codec,
      chatCompletionsCodec: _chatCompletionsCodec,
    );
    final response = await transport.send(
      buildOpenAILanguageModelTransportRequest(
        baseUrl: baseUrl,
        route: call.route,
        request: request,
        stream: false,
        body: preparedRequest.body,
        profile: profile,
        apiKey: apiKey,
        settings: settings,
      ),
    );

    return decodeOpenAILanguageModelGenerateResponse(
      call: call,
      body: response.body,
      warnings: preparedRequest.warnings,
      responsesCodec: _codec,
      chatCompletionsCodec: _chatCompletionsCodec,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
      GenerateTextRequest request) async* {
    final call = resolveOpenAILanguageModelCall(
      request: request,
      modelId: modelId,
      profile: profile,
      settings: settings,
    );
    final preparedRequest = encodeOpenAILanguageModelRequest(
      call: call,
      request: request,
      stream: true,
      responsesCodec: _codec,
      chatCompletionsCodec: _chatCompletionsCodec,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        buildOpenAILanguageModelTransportRequest(
          baseUrl: baseUrl,
          route: call.route,
          request: request,
          stream: true,
          body: preparedRequest.body,
          profile: profile,
          apiKey: apiKey,
          settings: settings,
        ),
      );

      yield* decodeOpenAILanguageModelStreamEvents(
        route: call.route,
        stream: response.stream,
        includeRawChunks: request.options.includeRawChunks,
        responsesCodec: _codec,
        chatCompletionsCodec: _chatCompletionsCodec,
      );
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }
}
