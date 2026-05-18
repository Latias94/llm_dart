import 'package:llm_dart_provider/llm_dart_provider.dart';

Future<SpeechGenerationResult> generateSpeech({
  required SpeechModel model,
  required String text,
  String? voice,
  String? outputFormat,
  String? instructions,
  double? speed,
  String? language,
  CallOptions callOptions = const CallOptions(),
}) {
  return model.doGenerate(
    SpeechGenerationRequest(
      text: text,
      voice: voice,
      outputFormat: outputFormat,
      instructions: instructions,
      speed: speed,
      language: language,
      callOptions: callOptions,
    ),
  );
}
