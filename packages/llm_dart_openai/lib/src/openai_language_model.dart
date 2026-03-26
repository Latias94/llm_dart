import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_options.dart';
import 'openai_responses_codec.dart';

final class OpenAILanguageModel implements LanguageModel {
  static const OpenAIResponsesCodec _codec = OpenAIResponsesCodec();

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
    String? baseUrl,
    this.settings = const OpenAIChatModelSettings(),
  }) : baseUrl = baseUrl ?? profile.defaultBaseUrl;

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
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    _ensureResponsesApi();

    final providerOptions = _resolveProviderOptions(
      request.callOptions.providerOptions,
    );
    final preparedRequest = _codec.encodeRequest(
      modelId: modelId,
      prompt: request.prompt,
      options: request.options,
      providerOptions: providerOptions,
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

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    _ensureResponsesApi();

    final providerOptions = _resolveProviderOptions(
      request.callOptions.providerOptions,
    );
    final preparedRequest = _codec.encodeRequest(
      modelId: modelId,
      prompt: request.prompt,
      options: request.options,
      providerOptions: providerOptions,
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
      final decoder = const DefaultSseDecoder();
      final chunks = utf8.decoder.bind(response.stream);

      await for (final frame in decoder.decode(chunks)) {
        if (frame.data.isEmpty || frame.data == '[DONE]') {
          continue;
        }

        for (final event in _codec.decodeStreamChunk(
          _decodeJsonObject(frame.data),
          streamState,
        )) {
          yield event;
        }
      }
    } catch (error) {
      yield ErrorEvent(error);
    }
  }

  void _ensureResponsesApi() {
    if (!settings.useResponsesApi) {
      throw UnsupportedError(
        'Chat Completions migration has not been implemented yet. Use responses API mode for the refactored package.',
      );
    }
  }

  OpenAIGenerateTextOptions _resolveProviderOptions(
    ProviderInvocationOptions? options,
  ) {
    if (options == null) {
      return const OpenAIGenerateTextOptions();
    }

    if (options is OpenAIGenerateTextOptions) {
      return options;
    }

    throw ArgumentError.value(
      options,
      'providerOptions',
      'Expected OpenAIGenerateTextOptions for OpenAI language models.',
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
}
