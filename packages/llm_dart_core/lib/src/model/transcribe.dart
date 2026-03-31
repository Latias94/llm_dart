import '../common/call_options.dart';
import 'transcription_model.dart';

Future<TranscriptionResult> transcribe({
  required TranscriptionModel model,
  required List<int> audioBytes,
  String? mediaType,
  CallOptions callOptions = const CallOptions(),
}) {
  if (audioBytes.isEmpty) {
    throw ArgumentError.value(
      audioBytes,
      'audioBytes',
      'transcribe(...) requires non-empty audio bytes.',
    );
  }

  return model.transcribe(
    TranscriptionRequest(
      audioBytes: audioBytes,
      mediaType: mediaType,
      callOptions: callOptions,
    ),
  );
}
