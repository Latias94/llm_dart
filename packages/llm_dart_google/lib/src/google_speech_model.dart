import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_model_describer.dart';
import 'google_options.dart';
import 'google_speech_model_request.dart';
import 'google_speech_model_response.dart';
import 'google_speech_model_transport.dart';

final class GoogleSpeechModel implements SpeechModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final GoogleSpeechModelSettings settings;

  @override
  final String modelId;

  GoogleSpeechModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const GoogleSpeechModelSettings(),
  })  : settings = resolveGoogleSpeechModelSettings(settings),
        baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerId => 'google';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeGoogleSpeechModel(
      modelId,
      settings: settings,
    );
  }

  Uri get generateContentUri => resolveGoogleSpeechGenerateContentUri(
        baseUrl: baseUrl,
        modelId: modelId,
      );

  @override
  Future<SpeechGenerationResult> doGenerate(
    SpeechGenerationRequest request,
  ) async {
    final options = resolveGoogleSpeechProviderOptions(request.callOptions);
    validateGoogleSpeechRequest(request, options);
    final warnings = buildGoogleSpeechRequestWarnings(request);

    final response = await transport.send(
      buildGoogleSpeechTransportRequest(
        baseUrl: baseUrl,
        modelId: modelId,
        callOptions: request.callOptions,
        body: buildGoogleSpeechRequestBody(
          request,
          settings: settings,
          options: options,
        ),
        apiKey: apiKey,
        settings: settings,
      ),
    );

    return decodeGoogleSpeechResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
      warnings: warnings,
    );
  }
}
