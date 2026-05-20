import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_speech_options.dart';

Map<String, Object?> buildOpenAISpeechRequestBody({
  required String modelId,
  required SpeechGenerationRequest request,
  required OpenAISpeechOptions? options,
  required String outputFormat,
}) {
  final instructions = request.instructions ?? options?.instructions;
  final speed = request.speed ?? options?.speed;

  return {
    'model': modelId,
    'input': request.text,
    'voice': request.voice ?? 'alloy',
    'response_format': outputFormat,
    if (instructions != null) 'instructions': instructions,
    if (speed != null) 'speed': speed,
  };
}
