import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_generate_content_codec.dart';
import 'google_language_model_support.dart';
import 'google_model_describer.dart';
import 'google_options.dart';
import 'google_result_codec.dart';
import 'google_stream_codec.dart';

final class GoogleLanguageModel
    implements LanguageModel, CapabilityDescribedModel {
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

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeGoogleChatModel(
      modelId,
      settings: settings,
    );
  }

  Uri get generateContentUri => Uri.parse(
      '${normalizeGoogleBaseUrl(baseUrl)}/models/$modelId:generateContent');

  Uri get streamGenerateContentUri => Uri.parse(
        '${normalizeGoogleBaseUrl(baseUrl)}/models/$modelId:streamGenerateContent?alt=sse',
      );

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    final providerOptions = resolveGoogleProviderOptions(request);
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
        headers: buildGoogleRequestHeaders(
          apiKey: apiKey,
          settings: settings,
          stream: false,
          extraHeaders: request.callOptions.headers,
        ),
        body: preparedRequest.body,
        timeout: request.callOptions.timeout,
        maxRetries: request.callOptions.maxRetries,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _resultCodec.decodeResponse(
      decodeGoogleJsonObject(response.body),
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    final providerOptions = resolveGoogleProviderOptions(request);
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
          headers: buildGoogleRequestHeaders(
            apiKey: apiKey,
            settings: settings,
            stream: true,
            extraHeaders: request.callOptions.headers,
          ),
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
          maxRetries: request.callOptions.maxRetries,
          cancellation: request.callOptions.cancellation,
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
}
