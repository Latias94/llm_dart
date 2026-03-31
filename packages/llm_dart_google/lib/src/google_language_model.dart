import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_generate_content_codec.dart';
import 'google_options.dart';
import 'google_response_format.dart';
import 'google_result_codec.dart';
import 'google_stream_codec.dart';

final class GoogleLanguageModel implements LanguageModel {
  static const GoogleGenerateContentCodec _requestCodec =
      GoogleGenerateContentCodec();
  static const GoogleGenerateContentResultCodec _resultCodec =
      GoogleGenerateContentResultCodec();
  static const GoogleGenerateContentStreamCodec _streamCodec =
      GoogleGenerateContentStreamCodec();
  static const SseJsonChunkParser _streamChunkParser = SseJsonChunkParser();

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
    final providerOptions = _resolveProviderOptions(request);
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
    final providerOptions = _resolveProviderOptions(request);
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
      await for (final chunk in _streamChunkParser.parse(response.stream)) {
        for (final event in _streamCodec.decodeChunk(
          chunk,
          state,
        )) {
          yield event;
        }
      }

      for (final event in _streamCodec.finish(state)) {
        yield event;
      }
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }

  GoogleGenerateTextOptions _resolveProviderOptions(
      GenerateTextRequest request) {
    final options = request.callOptions.providerOptions;
    final sharedResponseFormat = _resolveSharedResponseFormat(
      request.options.responseFormat,
    );

    GoogleGenerateTextOptions resolved;
    if (options == null) {
      resolved = const GoogleGenerateTextOptions();
    } else if (options is GoogleGenerateTextOptions) {
      resolved = options;
    } else {
      throw ArgumentError.value(
        options,
        'providerOptions',
        'Expected GoogleGenerateTextOptions for Google language models.',
      );
    }

    if (request.options.responseFormat != null &&
        resolved.responseFormat != null) {
      throw ArgumentError(
        'GenerateTextOptions.responseFormat and GoogleGenerateTextOptions.responseFormat cannot both be set.',
      );
    }

    if (sharedResponseFormat == null) {
      return resolved;
    }

    return GoogleGenerateTextOptions(
      candidateCount: resolved.candidateCount,
      thinkingBudgetTokens: resolved.thinkingBudgetTokens,
      thinkingLevel: resolved.thinkingLevel,
      includeThoughts: resolved.includeThoughts,
      responseModalities: resolved.responseModalities,
      cachedContent: resolved.cachedContent,
      safetySettings: resolved.safetySettings,
      tools: resolved.tools,
      includeServerSideToolInvocations:
          resolved.includeServerSideToolInvocations,
      responseFormat: sharedResponseFormat,
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

  GoogleJsonSchemaResponseFormat? _resolveSharedResponseFormat(
    ResponseFormat? responseFormat,
  ) {
    return switch (responseFormat) {
      null || TextResponseFormat() => null,
      JsonResponseFormat(schema: final schema) =>
        GoogleJsonSchemaResponseFormat(
          schema: schema.toJson(),
        ),
    };
  }
}
