import 'dart:async';

import '../client/google_client.dart';
import '../config/google_config.dart';

abstract class GoogleTTSCapability {
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request);

  Stream<GoogleTTSStreamEvent> generateSpeechStream(GoogleTTSRequest request);

  Future<List<GoogleVoiceInfo>> getAvailableVoices();

  Future<List<String>> getSupportedLanguages();
}

class GoogleTTSRequest {
  final String text;
  final Map<String, dynamic>? generationConfig;
  final String? model;

  const GoogleTTSRequest({
    required this.text,
    this.generationConfig,
    this.model,
  });

  Map<String, dynamic> toJson() => {
        'contents': [
          {
            'parts': [
              {'text': text}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          if (generationConfig != null) ...generationConfig!,
        },
        if (model != null) 'model': model,
      };
}

class GoogleVoiceInfo {
  final String name;
  final String description;

  const GoogleVoiceInfo({required this.name, required this.description});
}

class GoogleTTSResponse {
  final List<int> audioData;

  GoogleTTSResponse(this.audioData);
}

abstract class GoogleTTSStreamEvent {}

class GoogleTTSAudioChunk extends GoogleTTSStreamEvent {
  final List<int> audioData;

  GoogleTTSAudioChunk(this.audioData);
}

class GoogleTTS implements GoogleTTSCapability {
  final GoogleClient client;
  final GoogleConfig config;

  GoogleTTS(this.client, this.config);

  @override
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request) async {
    final model = request.model ?? config.model;
    final endpoint = 'models/$model:generateContent';

    final body = request.toJson();

    final response = await client.postJson(endpoint, body);
    final audioData = _extractAudio(response);
    return GoogleTTSResponse(audioData);
  }

  @override
  Stream<GoogleTTSStreamEvent> generateSpeechStream(
    GoogleTTSRequest request,
  ) async* {
    final model = request.model ?? config.model;
    final endpoint = 'models/$model:streamGenerateContent';

    final body = request.toJson();

    final stream = client.postStreamRaw(endpoint, body);
    await for (final chunk in stream) {
      final audio = _extractAudio({'candidates': []}); // placeholder
      if (audio.isNotEmpty) {
        yield GoogleTTSAudioChunk(audio);
      }
    }
  }

  @override
  Future<List<GoogleVoiceInfo>> getAvailableVoices() async {
    return [
      const GoogleVoiceInfo(name: 'Zephyr', description: 'Bright'),
      const GoogleVoiceInfo(name: 'Kore', description: 'Firm'),
    ];
  }

  @override
  Future<List<String>> getSupportedLanguages() async {
    return ['en-US'];
  }

  List<int> _extractAudio(Map<String, dynamic> response) {
    // Placeholder implementation; extend as needed with real audio extraction.
    return <int>[];
  }
}
