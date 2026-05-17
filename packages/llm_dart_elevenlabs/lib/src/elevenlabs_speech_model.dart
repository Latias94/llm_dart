import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_model_describer.dart';
import 'elevenlabs_options.dart';
import 'elevenlabs_shared.dart';
import 'elevenlabs_speech_model_request.dart';
import 'elevenlabs_speech_model_response.dart';
import 'elevenlabs_speech_model_transport.dart';

/// Package-owned modern ElevenLabs speech model surface.
final class ElevenLabsSpeechModel
    implements SpeechModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final ElevenLabsSpeechModelSettings settings;

  @override
  final String modelId;

  ElevenLabsSpeechModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const ElevenLabsSpeechModelSettings(),
  })  : baseUrl = normalizeElevenLabsBaseUrl(baseUrl),
        settings = resolveElevenLabsSpeechModelSettings(settings);

  @override
  String get providerId => 'elevenlabs';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeElevenLabsSpeechModel(
      modelId,
      settings: settings,
    );
  }

  Map<String, String> get defaultHeaders {
    return buildElevenLabsSpeechDefaultHeaders(
      apiKey: apiKey,
      settings: settings,
    );
  }

  @override
  Future<SpeechGenerationResult> doGenerate(
    SpeechGenerationRequest request,
  ) async {
    final options = resolveElevenLabsSpeechProviderOptions(request.callOptions);
    validateElevenLabsSpeechOptions(options);

    final voiceId = resolveElevenLabsSpeechVoiceId(
      requestVoice: request.voice,
      settings: settings,
    );
    final outputFormat = resolveElevenLabsSpeechOutputFormat(
      options?.outputFormat,
    );
    final response = await transport.send(
      buildElevenLabsSpeechTransportRequest(
        baseUrl: baseUrl,
        voiceId: voiceId,
        outputFormat: outputFormat,
        callOptions: request.callOptions,
        body: buildElevenLabsSpeechRequestBody(
          request,
          modelId: modelId,
          settings: settings,
          options: options,
        ),
        apiKey: apiKey,
        settings: settings,
        options: options,
      ),
    );

    return decodeElevenLabsSpeechResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
      outputFormat: outputFormat,
    );
  }
}
