import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_chat_request_codec.dart';
import 'ollama_chat_response_codec.dart';
import 'ollama_chat_stream_codec.dart';
import 'ollama_language_model_execution.dart';
import 'ollama_language_model_request.dart';
import 'ollama_language_model_response.dart';
import 'ollama_language_model_stream.dart';
import 'ollama_language_model_transport.dart';
import 'ollama_model_call_support.dart';
import 'ollama_model_describer.dart';
import 'ollama_model_settings.dart';

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
    ProviderModelOptions settings = const OllamaChatModelSettings(),
  })  : apiKey = normalizeOllamaApiKey(apiKey),
        baseUrl = normalizeOllamaBaseUrl(baseUrl),
        settings = resolveOllamaChatModelSettings(settings);

  @override
  String get providerId => 'ollama';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOllamaChatModel(
      modelId,
      settings: settings,
    );
  }

  Uri get chatUri => resolveOllamaChatRouteUri(baseUrl: baseUrl);

  Map<String, String> get defaultHeaders => buildOllamaChatDefaultHeaders(
        apiKey: apiKey,
        settings: settings,
      );

  OllamaChatRequestCodec get _requestCodec => buildOllamaChatRequestCodec(
        modelId: modelId,
        settings: settings,
      );

  OllamaChatResponseCodec get _responseCodec => buildOllamaChatResponseCodec(
        modelId: modelId,
      );

  OllamaChatStreamCodec get _streamCodec => buildOllamaChatStreamCodec(
        responseCodec: _responseCodec,
      );

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    final preparedRequest = await prepareOllamaChatRequest(
      requestCodec: _requestCodec,
      request: request,
      stream: false,
    );
    return sendOllamaModelRequest(
      transport: transport,
      request: buildOllamaChatGenerateTransportRequest(
        baseUrl: baseUrl,
        request: request,
        body: preparedRequest.body,
        defaultHeaders: defaultHeaders,
      ),
      decode: (body, _) => decodeOllamaChatGenerateResponse(
        body: body,
        responseCodec: _responseCodec,
        preparedRequest: preparedRequest,
      ),
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
      GenerateTextRequest request) async* {
    final preparedRequest = await prepareOllamaChatRequest(
      requestCodec: _requestCodec,
      request: request,
      stream: true,
    );
    yield* sendOllamaChatStreamCall(
      transport: transport,
      request: buildOllamaChatStreamTransportRequest(
        baseUrl: baseUrl,
        request: request,
        body: preparedRequest.body,
        defaultHeaders: defaultHeaders,
      ),
      preparedRequest: preparedRequest,
      streamCodec: _streamCodec,
      includeRawChunks: request.options.includeRawChunks,
    );
  }
}
