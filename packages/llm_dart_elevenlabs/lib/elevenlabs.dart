/// Modular ElevenLabs Provider
///
/// ElevenLabs specializes in text-to-speech and speech-to-text services.
library;

import 'defaults.dart';

import 'config.dart';
import 'provider.dart';

export 'audio.dart';
export 'client.dart';
export 'config.dart';
export 'dio_strategy.dart';
export 'forced_alignment.dart';
export 'models.dart';
export 'provider.dart';
export 'speech_to_speech.dart';

ElevenLabsProvider createElevenLabsProvider({
  required String apiKey,
  String baseUrl = elevenLabsBaseUrl,
  String? voiceId,
  String? model,
  Duration? timeout,
  double? stability,
  double? similarityBoost,
  double? style,
  bool? useSpeakerBoost,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    baseUrl: baseUrl,
    voiceId: voiceId,
    model: model,
    timeout: timeout,
    stability: stability,
    similarityBoost: similarityBoost,
    style: style,
    useSpeakerBoost: useSpeakerBoost,
  );

  return ElevenLabsProvider(config);
}

ElevenLabsProvider createElevenLabsTTSProvider({
  required String apiKey,
  String voiceId = elevenLabsDefaultVoiceId,
  String model = elevenLabsDefaultTTSModel,
  double stability = 0.5,
  double similarityBoost = 0.75,
  double style = 0.0,
  bool useSpeakerBoost = true,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    voiceId: voiceId,
    model: model,
    stability: stability,
    similarityBoost: similarityBoost,
    style: style,
    useSpeakerBoost: useSpeakerBoost,
  );

  return ElevenLabsProvider(config);
}

ElevenLabsProvider createElevenLabsSTTProvider({
  required String apiKey,
  String model = elevenLabsDefaultSTTModel,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    model: model,
  );

  return ElevenLabsProvider(config);
}

ElevenLabsProvider createElevenLabsCustomVoiceProvider({
  required String apiKey,
  required String voiceId,
  String model = elevenLabsDefaultTTSModel,
  double stability = 0.5,
  double similarityBoost = 0.75,
  double style = 0.0,
  bool useSpeakerBoost = true,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    voiceId: voiceId,
    model: model,
    stability: stability,
    similarityBoost: similarityBoost,
    style: style,
    useSpeakerBoost: useSpeakerBoost,
  );

  return ElevenLabsProvider(config);
}

ElevenLabsProvider createElevenLabsStreamingProvider({
  required String apiKey,
  String voiceId = elevenLabsDefaultVoiceId,
  String model = 'eleven_turbo_v2',
  double stability = 0.5,
  double similarityBoost = 0.75,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    voiceId: voiceId,
    model: model,
    stability: stability,
    similarityBoost: similarityBoost,
    timeout: const Duration(seconds: 30),
  );

  return ElevenLabsProvider(config);
}
