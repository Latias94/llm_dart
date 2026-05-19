import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GoogleSpeechSpeakerVoice {
  final String speaker;
  final String voice;

  const GoogleSpeechSpeakerVoice({
    required this.speaker,
    required this.voice,
  });
}

final class GoogleSpeechOptions implements ProviderInvocationOptions {
  final List<GoogleSpeechSpeakerVoice> speakers;
  final double? temperature;
  final double? topP;
  final int? topK;
  final int? maxOutputTokens;
  final List<String> stopSequences;

  const GoogleSpeechOptions({
    this.speakers = const [],
    this.temperature,
    this.topP,
    this.topK,
    this.maxOutputTokens,
    this.stopSequences = const [],
  });
}
