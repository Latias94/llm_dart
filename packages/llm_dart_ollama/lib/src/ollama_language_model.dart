import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_chat_request_codec.dart';
import 'ollama_chat_response_codec.dart';
import 'ollama_chat_stream_codec.dart';
import 'ollama_model_describer.dart';
import 'ollama_options.dart';

final class OllamaLanguageModel
    implements LanguageModel, CapabilityDescribedModel {
  final String? apiKey;
  final String baseUrl;
  final TransportClient transport;
  final OllamaChatModelSettings settings;

  @override
  final String modelId;

  OllamaLanguageModel({
    required this.modelId,
    required this.transport,
    String? apiKey,
    String? baseUrl,
    this.settings = const OllamaChatModelSettings(),
  })  : apiKey = normalizeOllamaApiKey(apiKey),
        baseUrl = normalizeOllamaBaseUrl(baseUrl);

  @override
  String get providerId => 'ollama';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOllamaChatModel(
      modelId,
      settings: settings,
    );
  }

  Uri get chatUri => resolveOllamaUri(baseUrl, '/api/chat');

  Map<String, String> get defaultHeaders => buildOllamaHeaders(
        apiKey: apiKey,
        contentType: 'application/json',
        headers: settings.headers,
      );

  OllamaChatRequestCodec get _requestCodec => OllamaChatRequestCodec(
        modelId: modelId,
        settings: settings,
      );

  OllamaChatResponseCodec get _responseCodec => OllamaChatResponseCodec(
        modelId: modelId,
      );

  OllamaChatStreamCodec get _streamCodec => OllamaChatStreamCodec(
        responseCodec: _responseCodec,
      );

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    final preparedRequest = await _requestCodec.encode(
      request: request,
      stream: false,
    );
    final response = await transport.send(
      TransportRequest(
        uri: chatUri,
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: preparedRequest.body,
        timeout: request.callOptions.timeout,
        maxRetries: request.callOptions.maxRetries,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _responseCodec.decodeGenerateResponse(
      decodeOllamaJsonObject(
        response.body,
        responseName: 'chat response',
      ),
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
      GenerateTextRequest request) async* {
    final preparedRequest = await _requestCodec.encode(
      request: request,
      stream: true,
    );
    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: chatUri,
          method: TransportMethod.post,
          headers: {
            ...defaultHeaders,
            'accept': 'application/x-ndjson',
            if (request.callOptions.headers case final headers?) ...headers,
          },
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
          maxRetries: request.callOptions.maxRetries,
          cancellation: request.callOptions.cancellation,
        ),
      );

      await for (final event in _streamCodec.decodeByteStream(
        response.stream,
        includeRawChunks: request.options.includeRawChunks,
      )) {
        yield event;
      }
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }
}
