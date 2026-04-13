import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_family_profile.dart';
import 'openai_language_model_support.dart';
import 'openai_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'openai_responses_codec.dart';

final class OpenAILanguageModel implements LanguageModel {
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

  Uri get responsesUri => Uri.parse('$baseUrl/responses');
  Uri get chatCompletionsUri => Uri.parse('$baseUrl/chat/completions');
  Map<String, String> get defaultHeaders => buildOpenAIDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
      );

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    final call = resolveOpenAILanguageModelCall(
      request: request,
      modelId: modelId,
      profile: profile,
      settings: settings,
    );
    if (call.usesResponsesApi) {
      final preparedRequest = _codec.encodeRequest(
        modelId: call.requestModelId,
        prompt: request.prompt,
        tools: request.tools,
        toolChoice: request.toolChoice,
        options: request.options,
        providerOptions: call.providerOptions.common,
        stream: false,
      );

      final response = await transport.send(
        TransportRequest(
          uri: responsesUri,
          method: TransportMethod.post,
          headers: buildOpenAIRequestHeaders(
            profile: profile,
            apiKey: apiKey,
            settings: settings,
            stream: false,
            extraHeaders: request.callOptions.headers,
          ),
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
          cancellation: request.callOptions.cancellation,
          responseType: TransportResponseType.json,
        ),
      );

      return _codec.decodeGenerateResponse(
        decodeOpenAIJsonObject(response.body),
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
      stream: false,
    );

    final response = await transport.send(
      TransportRequest(
        uri: chatCompletionsUri,
        method: TransportMethod.post,
        headers: buildOpenAIRequestHeaders(
          profile: profile,
          apiKey: apiKey,
          settings: settings,
          stream: false,
          extraHeaders: request.callOptions.headers,
        ),
        body: preparedRequest.body,
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _chatCompletionsCodec.decodeGenerateResponse(
      decodeOpenAIJsonObject(response.body),
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    final call = resolveOpenAILanguageModelCall(
      request: request,
      modelId: modelId,
      profile: profile,
      settings: settings,
    );
    if (call.usesResponsesApi) {
      final preparedRequest = _codec.encodeRequest(
        modelId: call.requestModelId,
        prompt: request.prompt,
        tools: request.tools,
        toolChoice: request.toolChoice,
        options: request.options,
        providerOptions: call.providerOptions.common,
        stream: true,
      );

      yield StartEvent(warnings: preparedRequest.warnings);

      try {
        final response = await transport.sendStream(
          TransportRequest(
            uri: responsesUri,
            method: TransportMethod.post,
            headers: buildOpenAIRequestHeaders(
              profile: profile,
              apiKey: apiKey,
              settings: settings,
              stream: true,
              extraHeaders: request.callOptions.headers,
            ),
            body: preparedRequest.body,
            timeout: request.callOptions.timeout,
            cancellation: request.callOptions.cancellation,
          ),
        );

        final streamState = OpenAIResponsesStreamState();
        await for (final chunk in _streamChunkParser.parse(response.stream)) {
          final events = _codec.decodeStreamChunk(
            chunk,
            streamState,
          );

          for (final event in events) {
            yield event;
          }
        }
      } catch (error) {
        yield ErrorEvent(transportErrorToModelError(error));
      }

      return;
    }

    final preparedRequest = _chatCompletionsCodec.encodeRequest(
      modelId: call.requestModelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      providerOptions: call.providerOptions,
      stream: true,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: chatCompletionsUri,
          method: TransportMethod.post,
          headers: buildOpenAIRequestHeaders(
            profile: profile,
            apiKey: apiKey,
            settings: settings,
            stream: true,
            extraHeaders: request.callOptions.headers,
          ),
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
          cancellation: request.callOptions.cancellation,
        ),
      );

      final streamState = OpenAIChatCompletionsStreamState();
      await for (final chunk in _streamChunkParser.parse(response.stream)) {
        final events = _chatCompletionsCodec.decodeStreamChunk(
          chunk,
          streamState,
        );

        for (final event in events) {
          yield event;
        }
      }
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }
}
