import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_chat_completions_codec.dart';
import 'openai_family_profile.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openrouter_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';
import 'openai_responses_codec.dart';
import 'xai_options.dart';

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
  })  : settings = _resolveModelSettingsForProfile(profile, settings),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  Uri get responsesUri => Uri.parse('$baseUrl/responses');
  Uri get chatCompletionsUri => Uri.parse('$baseUrl/chat/completions');

  Map<String, String> get defaultHeaders => profile.buildHeaders(
        apiKey: apiKey,
        extraHeaders: {
          if (settings.common.organization case final organization?)
            'openai-organization': organization,
          if (settings.common.project case final project?)
            'openai-project': project,
          ...settings.common.headers,
        },
      );

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    final providerOptions = _resolveProviderOptions(request);
    if (_usesResponsesApi) {
      final preparedRequest = _codec.encodeRequest(
        modelId: _requestModelId,
        prompt: request.prompt,
        tools: request.tools,
        toolChoice: request.toolChoice,
        options: request.options,
        providerOptions: providerOptions.common,
        stream: false,
      );

      final response = await transport.send(
        TransportRequest(
          uri: responsesUri,
          method: TransportMethod.post,
          headers: _buildRequestHeaders(
            stream: false,
            extraHeaders: request.callOptions.headers,
          ),
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
          responseType: TransportResponseType.json,
        ),
      );

      return _codec.decodeGenerateResponse(
        _decodeJsonObject(response.body),
        warnings: preparedRequest.warnings,
      );
    }

    final preparedRequest = _chatCompletionsCodec.encodeRequest(
      modelId: _requestModelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      providerOptions: providerOptions,
      stream: false,
    );

    final response = await transport.send(
      TransportRequest(
        uri: chatCompletionsUri,
        method: TransportMethod.post,
        headers: _buildRequestHeaders(
          stream: false,
          extraHeaders: request.callOptions.headers,
        ),
        body: preparedRequest.body,
        timeout: request.callOptions.timeout,
        responseType: TransportResponseType.json,
      ),
    );

    return _chatCompletionsCodec.decodeGenerateResponse(
      _decodeJsonObject(response.body),
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    final providerOptions = _resolveProviderOptions(request);
    final useResponsesApi = _usesResponsesApi;
    if (useResponsesApi) {
      final preparedRequest = _codec.encodeRequest(
        modelId: _requestModelId,
        prompt: request.prompt,
        tools: request.tools,
        toolChoice: request.toolChoice,
        options: request.options,
        providerOptions: providerOptions.common,
        stream: true,
      );

      yield StartEvent(warnings: preparedRequest.warnings);

      try {
        final response = await transport.sendStream(
          TransportRequest(
            uri: responsesUri,
            method: TransportMethod.post,
            headers: _buildRequestHeaders(
              stream: true,
              extraHeaders: request.callOptions.headers,
            ),
            body: preparedRequest.body,
            timeout: request.callOptions.timeout,
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
      modelId: _requestModelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      providerOptions: providerOptions,
      stream: true,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: chatCompletionsUri,
          method: TransportMethod.post,
          headers: _buildRequestHeaders(
            stream: true,
            extraHeaders: request.callOptions.headers,
          ),
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
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

  bool get _usesResponsesApi =>
      settings.common.useResponsesApi && profile.supportsResponsesApi;

  String get _requestModelId {
    final search = settings.openRouterSearch;
    if (search == null) {
      return modelId;
    }

    if (profile.providerId != 'openrouter') {
      return modelId;
    }

    return switch (search.mode) {
      OpenRouterSearchMode.onlineModel => _withOpenRouterOnlineModel(modelId),
    };
  }

  ResolvedOpenAIGenerateTextOptions _resolveProviderOptions(
    GenerateTextRequest request,
  ) {
    final options = request.callOptions.providerOptions;
    final sharedResponseFormat = _resolveSharedResponseFormat(
      request.options.responseFormat,
    );

    OpenAIGenerateTextOptions common = const OpenAIGenerateTextOptions();
    XAILiveSearchOptions? xaiSearch;

    if (options == null) {
      common = const OpenAIGenerateTextOptions();
    } else if (options is OpenAIGenerateTextOptions) {
      common = options;
    } else if (options is XAIGenerateTextOptions) {
      if (profile.providerId != 'xai') {
        throw ArgumentError.value(
          options,
          'providerOptions',
          'XAIGenerateTextOptions are only valid for xAI language models.',
        );
      }

      common = options.common;
      xaiSearch = options.search;
    } else {
      throw ArgumentError.value(
        options,
        'providerOptions',
        'Expected OpenAIGenerateTextOptions or profile-specific OpenAI-family provider options.',
      );
    }

    if (request.options.responseFormat != null &&
        common.responseFormat != null) {
      throw ArgumentError(
        'GenerateTextOptions.responseFormat and OpenAIGenerateTextOptions.responseFormat cannot both be set.',
      );
    }

    if (common.builtInTools == null &&
        settings.common.builtInTools.isNotEmpty) {
      common = common.copyWith(
        builtInTools: settings.common.builtInTools,
      );
    }

    if (sharedResponseFormat != null) {
      common = common.copyWith(
        responseFormat: sharedResponseFormat,
      );
    }

    return ResolvedOpenAIGenerateTextOptions(
      common: common,
      xaiSearch: xaiSearch,
    );
  }

  Map<String, String> _buildRequestHeaders({
    required bool stream,
    Map<String, String>? extraHeaders,
  }) {
    return {
      ...defaultHeaders,
      'content-type': 'application/json',
      'accept': stream ? 'text/event-stream' : 'application/json',
      if (extraHeaders != null) ...extraHeaders,
    };
  }

  Map<String, Object?> _decodeJsonObject(Object? body) {
    if (body is Map<String, Object?>) {
      return body;
    }

    if (body is Map) {
      return Map<String, Object?>.from(body);
    }

    if (body is String) {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    }

    throw StateError(
      'Expected an OpenAI JSON object response but received ${body.runtimeType}.',
    );
  }

  static ResolvedOpenAIChatModelSettings _resolveModelSettingsForProfile(
    OpenAIFamilyProfile profile,
    ProviderModelOptions settings,
  ) {
    if (settings is OpenAIChatModelSettings) {
      return ResolvedOpenAIChatModelSettings(
        common: settings,
      );
    }

    if (settings is OpenRouterChatModelSettings) {
      if (profile.providerId != 'openrouter') {
        throw ArgumentError.value(
          settings,
          'settings',
          'OpenRouterChatModelSettings are only valid for OpenRouter language models.',
        );
      }

      return ResolvedOpenAIChatModelSettings(
        common: settings.common,
        openRouterSearch: settings.search,
      );
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected OpenAIChatModelSettings or profile-specific OpenAI-family model settings.',
    );
  }

  static String _withOpenRouterOnlineModel(String modelId) {
    if (modelId.endsWith(':online')) {
      return modelId;
    }

    if (modelId.contains('deepseek-r1')) {
      throw UnsupportedError(
        'OpenRouter online-model shaping is not supported for DeepSeek R1 traffic.',
      );
    }

    return '$modelId:online';
  }

  OpenAIJsonSchemaResponseFormat? _resolveSharedResponseFormat(
    ResponseFormat? responseFormat,
  ) {
    return switch (responseFormat) {
      null || TextResponseFormat() => null,
      JsonResponseFormat(
        schema: final schema,
        name: final name,
        description: final description,
        strict: final strict,
      ) =>
        OpenAIJsonSchemaResponseFormat(
          name: name ?? 'structured_output',
          description: description,
          schema: schema.toJson(),
          strict: strict,
        ),
    };
  }
}
