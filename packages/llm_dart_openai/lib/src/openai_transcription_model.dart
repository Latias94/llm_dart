import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_model_describer.dart';
import 'openai_model_settings.dart';
import 'openai_transcription_model_request.dart';
import 'openai_transcription_model_response.dart';
import 'openai_transcription_model_transport.dart';

final class OpenAITranscriptionModel
    implements TranscriptionModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAITranscriptionModelSettings settings;

  @override
  final String modelId;

  OpenAITranscriptionModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAITranscriptionModelSettings(),
  })  : settings = resolveOpenAITranscriptionModelSettings(settings),
        baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile);

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAITranscriptionModel(
      modelId,
      profile: profile,
    );
  }

  Uri get transcriptionUri => resolveOpenAITranscriptionUri(baseUrl: baseUrl);

  Map<String, String> get defaultHeaders =>
      buildOpenAITranscriptionDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
      );

  @override
  Future<TranscriptionResult> doGenerate(TranscriptionRequest request) async {
    final options =
        resolveOpenAITranscriptionProviderOptions(request.callOptions);
    validateOpenAITranscriptionOptions(options);
    final responseFormat = resolveOpenAITranscriptionResponseFormat(
      modelId: modelId,
      options: options,
    );
    validateOpenAITranscriptionTimestampResponseFormat(
      modelId: modelId,
      responseFormat: responseFormat,
      options: options,
    );

    final multipart = buildOpenAITranscriptionMultipartBody(
      modelId: modelId,
      request: request,
      options: options,
      responseFormat: responseFormat,
    );

    final response = await transport.send(
      buildOpenAITranscriptionTransportRequest(
        baseUrl: baseUrl,
        callOptions: request.callOptions,
        multipart: multipart,
        defaultHeaders: defaultHeaders,
        responseFormat: responseFormat,
      ),
    );

    return decodeOpenAITranscriptionResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
      responseFormat: responseFormat,
    );
  }
}
