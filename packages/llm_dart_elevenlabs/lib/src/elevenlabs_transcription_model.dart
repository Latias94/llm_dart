import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_model_describer.dart';
import 'elevenlabs_options.dart';
import 'elevenlabs_shared.dart';
import 'elevenlabs_transcription_model_request.dart';
import 'elevenlabs_transcription_model_response.dart';
import 'elevenlabs_transcription_model_transport.dart';

/// Package-owned modern ElevenLabs transcription model surface.
final class ElevenLabsTranscriptionModel
    implements TranscriptionModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final ElevenLabsTranscriptionModelSettings settings;

  @override
  final String modelId;

  ElevenLabsTranscriptionModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings =
        const ElevenLabsTranscriptionModelSettings(),
  })  : baseUrl = normalizeElevenLabsBaseUrl(baseUrl),
        settings = resolveElevenLabsTranscriptionModelSettings(settings);

  @override
  String get providerId => 'elevenlabs';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeElevenLabsTranscriptionModel(modelId);
  }

  Map<String, String> get defaultHeaders {
    return buildElevenLabsTranscriptionDefaultHeaders(
      apiKey: apiKey,
      settings: settings,
    );
  }

  @override
  Future<TranscriptionResult> doGenerate(TranscriptionRequest request) async {
    final options = resolveElevenLabsTranscriptionProviderOptions(
      request.callOptions,
    );
    validateElevenLabsTranscriptionOptions(options);

    final multipart = buildElevenLabsTranscriptionMultipartBody(
      request,
      modelId: modelId,
      options: options,
    );

    final response = await transport.send(
      buildElevenLabsTranscriptionTransportRequest(
        baseUrl: baseUrl,
        callOptions: request.callOptions,
        multipart: multipart,
        apiKey: apiKey,
        settings: settings,
        options: options,
      ),
    );

    return decodeElevenLabsTranscriptionResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
    );
  }
}
