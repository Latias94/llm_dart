import '../common/call_options.dart';
import 'speech_model.dart';

Future<SpeechGenerationResult> generateSpeech({
  required SpeechModel model,
  required String text,
  String? voice,
  CallOptions callOptions = const CallOptions(),
}) {
  return model.generateSpeech(
    SpeechGenerationRequest(
      text: text,
      voice: voice,
      callOptions: callOptions,
    ),
  );
}
