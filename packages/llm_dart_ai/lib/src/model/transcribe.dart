import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'non_text_request_support.dart';

final class TranscribeRequest {
  final TranscriptionModel model;
  final List<int> audioBytes;
  final String mediaType;
  final CallOptions callOptions;

  TranscribeRequest({
    required this.model,
    required List<int> audioBytes,
    required this.mediaType,
    this.callOptions = const CallOptions(),
  }) : audioBytes = List.unmodifiable(audioBytes) {
    _validate();
  }

  TranscriptionRequest toProviderRequest() {
    return TranscriptionRequest(
      audioBytes: audioBytes,
      mediaType: mediaType,
      callOptions: callOptions,
    );
  }

  void _validate() {
    if (audioBytes.isEmpty) {
      throw ArgumentError.value(
        audioBytes,
        'audioBytes',
        'TranscribeRequest requires non-empty audio bytes.',
      );
    }

    if (mediaType.isEmpty) {
      throw ArgumentError.value(
        mediaType,
        'mediaType',
        'TranscribeRequest requires a non-empty audio media type.',
      );
    }

    requireDescribedModelCapability(
      model: model,
      kind: ModelCapabilityKind.transcription,
      usageContext: 'TranscribeRequest',
    );
  }
}

Future<TranscriptionResult> transcribe({
  required TranscriptionModel model,
  required List<int> audioBytes,
  required String mediaType,
  CallOptions callOptions = const CallOptions(),
}) {
  return transcribeForRequest(
    TranscribeRequest(
      model: model,
      audioBytes: audioBytes,
      mediaType: mediaType,
      callOptions: callOptions,
    ),
  );
}

Future<TranscriptionResult> transcribeForRequest(TranscribeRequest request) {
  return request.model.doGenerate(request.toProviderRequest());
}
