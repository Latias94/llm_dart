import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'non_text_request_support.dart';

final class GenerateSpeechRequest {
  final SpeechModel model;
  final String text;
  final String? voice;
  final String? outputFormat;
  final String? instructions;
  final double? speed;
  final String? language;
  final CallOptions callOptions;

  GenerateSpeechRequest({
    required this.model,
    required this.text,
    this.voice,
    this.outputFormat,
    this.instructions,
    this.speed,
    this.language,
    this.callOptions = const CallOptions(),
  }) {
    _validate();
  }

  SpeechGenerationRequest toProviderRequest() {
    return SpeechGenerationRequest(
      text: text,
      voice: voice,
      outputFormat: outputFormat,
      instructions: instructions,
      speed: speed,
      language: language,
      callOptions: callOptions,
    );
  }

  void _validate() {
    if (text.isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'GenerateSpeechRequest requires non-empty text.',
      );
    }

    requireDescribedModelCapability(
      model: model,
      kind: ModelCapabilityKind.speech,
      usageContext: 'GenerateSpeechRequest',
    );

    if (voice != null) {
      requireDescribedModelCapability(
        model: model,
        kind: ModelCapabilityKind.speech,
        featureId: ModelCapabilityFeatureIds.speechVoiceSelection,
        usageContext: 'GenerateSpeechRequest.voice',
      );
    }

    if (outputFormat != null) {
      requireDescribedModelCapability(
        model: model,
        kind: ModelCapabilityKind.speech,
        featureId: ModelCapabilityFeatureIds.speechOutputFormat,
        usageContext: 'GenerateSpeechRequest.outputFormat',
      );
    }
  }
}

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
  return generateSpeechForRequest(
    GenerateSpeechRequest(
      model: model,
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

Future<SpeechGenerationResult> generateSpeechForRequest(
  GenerateSpeechRequest request,
) {
  return request.model.doGenerate(request.toProviderRequest());
}
