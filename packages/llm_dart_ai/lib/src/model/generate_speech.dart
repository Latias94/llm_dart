import 'package:llm_dart_provider/llm_dart_provider.dart';

Future<SpeechGenerationResult> generateSpeech({
  required SpeechModel model,
  required String text,
  String? voice,
  CallOptions callOptions = const CallOptions(),
}) {
  return model.doGenerate(
    SpeechGenerationRequest(
      text: text,
      voice: voice,
      callOptions: callOptions,
    ),
  );
}
