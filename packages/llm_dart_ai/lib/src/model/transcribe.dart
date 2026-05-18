import 'package:llm_dart_provider/llm_dart_provider.dart';

Future<TranscriptionResult> transcribe({
  required TranscriptionModel model,
  required List<int> audioBytes,
  required String mediaType,
  CallOptions callOptions = const CallOptions(),
}) {
  if (audioBytes.isEmpty) {
    throw ArgumentError.value(
      audioBytes,
      'audioBytes',
      'transcribe(...) requires non-empty audio bytes.',
    );
  }

  if (mediaType.isEmpty) {
    throw ArgumentError.value(
      mediaType,
      'mediaType',
      'transcribe(...) requires a non-empty audio media type.',
    );
  }

  return model.doGenerate(
    TranscriptionRequest(
      audioBytes: audioBytes,
      mediaType: mediaType,
      callOptions: callOptions,
    ),
  );
}
