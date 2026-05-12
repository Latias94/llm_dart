import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_model_describer.dart';
import 'openai_family_profile.dart';
import 'openai_language_model_support.dart';
import 'openai_options.dart';
import 'openrouter_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'openai_responses_codec.dart';

final class OpenAILanguageModel
    implements LanguageModel, CapabilityDescribedModel {
  static const OpenAIResponsesCodec _codec = OpenAIResponsesCodec();
  static const SseJsonChunkParser _streamChunkParser = SseJsonChunkParser();
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final ResolvedOpenAIChatModelSettings settings;
  late final OpenAIChatCompletionsCodec _chatCompletionsCodec =
      OpenAIChatCompletionsCodec(
    providerNamespace: profile.providerId,
  );

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
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

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
    final preparedRequest = _encodeRequest(
      call: call,
      request: request,
      stream: false,
    );
    final response = await transport.send(
      _buildTransportRequest(
        route: call.route,
        request: request,
        stream: false,
        body: preparedRequest.body,
      ),
    );

    return _decodeGenerateResponse(
      call: call,
      body: response.body,
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<TextStreamEvent> doStream(GenerateTextRequest request) async* {
    final call = resolveOpenAILanguageModelCall(
      request: request,
      modelId: modelId,
      profile: profile,
      settings: settings,
    );
    final preparedRequest = _encodeRequest(
      call: call,
      request: request,
      stream: true,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        _buildTransportRequest(
          route: call.route,
          request: request,
          stream: true,
          body: preparedRequest.body,
        ),
      );

      yield* _decodeStreamEvents(
        route: call.route,
        stream: response.stream,
        includeRawChunks: request.options.includeRawChunks,
      );
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }

  _PreparedOpenAILanguageModelRequest _encodeRequest({
    required ResolvedOpenAILanguageModelCall call,
    required GenerateTextRequest request,
    required bool stream,
  }) {
    if (call.usesResponsesApi) {
      final preparedRequest = _codec.encodeRequest(
        modelId: call.requestModelId,
        prompt: request.prompt,
        tools: request.tools,
        toolChoice: request.toolChoice,
        options: request.options,
        providerOptions: call.providerOptions.common,
        stream: stream,
      );
      return _PreparedOpenAILanguageModelRequest(
        body: preparedRequest.body,
        warnings: preparedRequest.warnings,
      );
    }

    final preparedRequest = _chatCompletionsCodec.encodeRequest(
      modelId: call.requestModelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      providerOptions: call.providerOptions,
      stream: stream,
    );
    return _PreparedOpenAILanguageModelRequest(
      body: preparedRequest.body,
      warnings: preparedRequest.warnings,
    );
  }

  TransportRequest _buildTransportRequest({
    required OpenAIRequestRoute route,
    required GenerateTextRequest request,
    required bool stream,
    required Object? body,
  }) {
    return TransportRequest(
      uri: _routeUri(route),
      method: TransportMethod.post,
      headers: buildOpenAIRequestHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
        stream: stream,
        extraHeaders: request.callOptions.headers,
      ),
      body: body,
      timeout: request.callOptions.timeout,
      maxRetries: request.callOptions.maxRetries,
      cancellation: request.callOptions.cancellation,
      responseType: TransportResponseType.json,
    );
  }

  Uri _routeUri(OpenAIRequestRoute route) => switch (route) {
        OpenAIRequestRoute.responses => responsesUri,
        OpenAIRequestRoute.chatCompletions => chatCompletionsUri,
      };

  GenerateTextResult _decodeGenerateResponse({
    required ResolvedOpenAILanguageModelCall call,
    required Object? body,
    required List<ModelWarning> warnings,
  }) {
    final json = decodeOpenAIJsonObject(body);
    if (call.usesResponsesApi) {
      return _codec.decodeGenerateResponse(
        json,
        warnings: warnings,
      );
    }

    return _chatCompletionsCodec.decodeGenerateResponse(
      json,
      warnings: warnings,
    );
  }

  Stream<TextStreamEvent> _decodeStreamEvents({
    required OpenAIRequestRoute route,
    required Stream<List<int>> stream,
    required bool includeRawChunks,
  }) async* {
    if (route == OpenAIRequestRoute.responses) {
      final streamState = OpenAIResponsesStreamState();
      await for (final chunk in _streamChunkParser.parse(stream)) {
        if (includeRawChunks) {
          yield RawChunkEvent(chunk);
        }
        for (final event in _codec.decodeStreamChunk(chunk, streamState)) {
          yield event;
        }
      }
      return;
    }

    final streamState = OpenAIChatCompletionsStreamState();
    await for (final chunk in _streamChunkParser.parse(stream)) {
      if (includeRawChunks) {
        yield RawChunkEvent(chunk);
      }
      for (final event in _chatCompletionsCodec.decodeStreamChunk(
        chunk,
        streamState,
      )) {
        yield event;
      }
    }
  }
}

final class _PreparedOpenAILanguageModelRequest {
  final Object? body;
  final List<ModelWarning> warnings;

  const _PreparedOpenAILanguageModelRequest({
    required this.body,
    required this.warnings,
  });
}
