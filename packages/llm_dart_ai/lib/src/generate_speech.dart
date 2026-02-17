import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'types.dart';

/// Generate speech audio (TTS) using a provider-agnostic capability.
Future<GenerateSpeechResult> generateSpeech({
  required TextToSpeechCapability model,
  required TTSRequest request,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final TTSResponse response;

  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  if (effectiveCallOptions.isEmpty) {
    response = await model.textToSpeech(request, cancelToken: cancelToken);
  } else {
    if (model is! TextToSpeechCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for text-to-speech. '
        'Implement `TextToSpeechCallOptionsCapability` (or use a provider that does).',
      );
    }

    response = await (model as TextToSpeechCallOptionsCapability)
        .textToSpeechWithCallOptions(
      request,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  if (response.audioData.isEmpty) {
    throw NoSpeechGeneratedError(
        response: response, responses: response.responses);
  }

  return GenerateSpeechResult(rawResponse: response);
}

/// Convenience helper to generate speech from plain text.
Future<GenerateSpeechResult> generateSpeechFromText({
  required TextToSpeechCapability model,
  required String text,
  String? voice,
  String? modelId,
  String? format,
  int? sampleRate,
  String? languageCode,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return generateSpeech(
    model: model,
    request: TTSRequest(
      text: text,
      voice: voice,
      model: modelId,
      format: format,
      sampleRate: sampleRate,
      languageCode: languageCode,
    ),
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Stream speech audio (TTS) as provider-agnostic audio stream events.
Stream<AudioStreamEvent> streamSpeech({
  required StreamingTextToSpeechCapability model,
  required TTSRequest request,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  if (effectiveCallOptions.isEmpty) {
    return model.textToSpeechStream(request, cancelToken: cancelToken);
  }

  if (model is! StreamingTextToSpeechCallOptionsCapability) {
    throw const InvalidRequestError(
      'This model does not support call-level overrides (headers/body) for streaming text-to-speech. '
      'Implement `StreamingTextToSpeechCallOptionsCapability` (or use a provider that does).',
    );
  }

  return (model as StreamingTextToSpeechCallOptionsCapability)
      .textToSpeechStreamWithCallOptions(
    request,
    callOptions: effectiveCallOptions,
    cancelToken: cancelToken,
  );
}

/// Convenience helper to stream speech from plain text.
Stream<AudioStreamEvent> streamSpeechFromText({
  required StreamingTextToSpeechCapability model,
  required String text,
  String? voice,
  String? modelId,
  String? format,
  int? sampleRate,
  String? languageCode,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return streamSpeech(
    model: model,
    request: TTSRequest(
      text: text,
      voice: voice,
      model: modelId,
      format: format,
      sampleRate: sampleRate,
      languageCode: languageCode,
      processingMode: AudioProcessingMode.streaming,
    ),
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}
