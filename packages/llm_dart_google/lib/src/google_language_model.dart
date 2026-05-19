import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_language_model_request.dart';
import 'google_language_model_response.dart';
import 'google_language_model_support.dart';
import 'google_language_model_stream.dart';
import 'google_language_model_transport.dart';
import 'google_model_describer.dart';
import 'google_model_settings.dart';

final class GoogleLanguageModel
    implements LanguageModel, CapabilityDescribedModel {
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
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    final preparedRequest = encodeGoogleLanguageModelRequest(
      modelId: modelId,
      request: request,
      settings: settings,
    );

    final response = await transport.send(
      buildGoogleLanguageModelTransportRequest(
        baseUrl: baseUrl,
        modelId: modelId,
        request: request,
        stream: false,
        body: preparedRequest.body,
        apiKey: apiKey,
        settings: settings,
      ),
    );

    return decodeGoogleLanguageModelGenerateResponse(
      body: response.body,
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
      GenerateTextRequest request) async* {
    final preparedRequest = encodeGoogleLanguageModelRequest(
      modelId: modelId,
      request: request,
      settings: settings,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        buildGoogleLanguageModelTransportRequest(
          baseUrl: baseUrl,
          modelId: modelId,
          request: request,
          stream: true,
          body: preparedRequest.body,
          apiKey: apiKey,
          settings: settings,
        ),
      );

      yield* decodeGoogleLanguageModelStreamEvents(
        stream: response.stream,
        includeRawChunks: request.options.includeRawChunks,
      );
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }
}
