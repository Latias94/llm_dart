import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_generate_content_codec.dart';
import 'google_options.dart';
import 'google_result_codec.dart';
import 'google_stream_codec.dart';

final class GoogleLanguageModel implements LanguageModel {
  static const GoogleGenerateContentCodec _requestCodec =
      GoogleGenerateContentCodec();
  static const GoogleGenerateContentResultCodec _resultCodec =
      GoogleGenerateContentResultCodec();
  static const GoogleGenerateContentStreamCodec _streamCodec =
      GoogleGenerateContentStreamCodec();

  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final GoogleChatModelSettings settings;

  @override
  final String modelId;

  GoogleLanguageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    this.settings = const GoogleChatModelSettings(),
  }) : baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerId => 'google';

  Uri get generateContentUri =>
      Uri.parse('${_normalizedBaseUrl()}/models/$modelId:generateContent');

  Uri get streamGenerateContentUri => Uri.parse(
        '${_normalizedBaseUrl()}/models/$modelId:streamGenerateContent?alt=sse',
      );

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    final providerOptions = _resolveProviderOptions(
      request.callOptions.providerOptions,
    );
    final preparedRequest = _requestCodec.encodeRequest(
      modelId: modelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      settings: settings,
      providerOptions: providerOptions,
    );

    final response = await transport.send(
      TransportRequest(
        uri: generateContentUri,
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

    return _resultCodec.decodeResponse(
      _decodeJsonObject(response.body),
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    final providerOptions = _resolveProviderOptions(
      request.callOptions.providerOptions,
    );
    final preparedRequest = _requestCodec.encodeRequest(
      modelId: modelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      settings: settings,
      providerOptions: providerOptions,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: streamGenerateContentUri,
          method: TransportMethod.post,
          headers: _buildRequestHeaders(
            stream: true,
            extraHeaders: request.callOptions.headers,
          ),
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
        ),
      );

      final state = GoogleGenerateContentStreamState();
      final decoder = const DefaultSseDecoder();
      final chunks = utf8.decoder.bind(response.stream);

      await for (final frame in decoder.decode(chunks)) {
        if (frame.data.isEmpty || frame.data == '[DONE]') {
          continue;
        }

        for (final event in _streamCodec.decodeChunk(
          _decodeJsonObject(frame.data),
          state,
        )) {
          yield event;
        }
      }

      for (final event in _streamCodec.finish(state)) {
        yield event;
      }
    } catch (error) {
      yield ErrorEvent(error);
    }
  }

  GoogleGenerateTextOptions _resolveProviderOptions(
    ProviderInvocationOptions? options,
  ) {
    if (options == null) {
      return const GoogleGenerateTextOptions();
    }

    if (options is GoogleGenerateTextOptions) {
      return options;
    }

    throw ArgumentError.value(
      options,
      'providerOptions',
      'Expected GoogleGenerateTextOptions for Google language models.',
    );
  }

  Map<String, String> _buildRequestHeaders({
    required bool stream,
    Map<String, String>? extraHeaders,
  }) {
    return {
      'x-goog-api-key': apiKey,
      'content-type': 'application/json',
      'accept': stream ? 'text/event-stream' : 'application/json',
      ...settings.headers,
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
      'Expected a Google JSON object response but received ${body.runtimeType}.',
    );
  }

  String _normalizedBaseUrl() {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }
}
