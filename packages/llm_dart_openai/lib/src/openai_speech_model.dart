import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_model_describer.dart';
import 'openai_speech_model_request.dart';
import 'openai_speech_model_response.dart';
import 'openai_options.dart';
import 'openai_speech_model_transport.dart';

final class OpenAISpeechModel implements SpeechModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAISpeechModelSettings settings;

  @override
  final String modelId;

  OpenAISpeechModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAISpeechModelSettings(),
  })  : settings = resolveOpenAISpeechModelSettings(settings),
        baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile);

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAISpeechModel(
      modelId,
      profile: profile,
    );
  }

  Uri get speechUri => resolveOpenAISpeechUri(baseUrl: baseUrl);

  Map<String, String> get defaultHeaders => buildOpenAISpeechDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
      );

  @override
  Future<SpeechGenerationResult> doGenerate(
    SpeechGenerationRequest request,
  ) async {
    final options = resolveOpenAISpeechProviderOptions(request.callOptions);
    validateOpenAISpeechRequest(request, options);
    final warnings = <ModelWarning>[];
    final outputFormat = resolveOpenAISpeechOutputFormat(
      request,
      options,
      warnings: warnings,
    );
    warnOpenAISpeechLanguageUnsupported(request, options, warnings);

    final response = await transport.send(
      buildOpenAISpeechTransportRequest(
        baseUrl: baseUrl,
        callOptions: request.callOptions,
        body: buildOpenAISpeechRequestBody(
          modelId: modelId,
          request: request,
          options: options,
          outputFormat: outputFormat,
        ),
        defaultHeaders: defaultHeaders,
      ),
    );

    return decodeOpenAISpeechResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
      outputFormat: outputFormat,
      warnings: warnings,
    );
  }
}
