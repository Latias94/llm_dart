part of 'elevenlabs_audio_support.dart';

final class _ElevenLabsAudioResponseSupport {
  const _ElevenLabsAudioResponseSupport();

  TTSResponse buildTextToSpeechResponse(
    Uint8List audioData, {
    required TTSRequest request,
    String? contentType,
  }) {
    return TTSResponse(
      audioData: audioData,
      contentType: contentType,
      voice: request.voice,
      model: request.model,
      duration: null,
      sampleRate: null,
      usage: null,
    );
  }

  STTResponse parseSpeechToTextResponse(
    Map<String, dynamic> responseData, {
    required STTRequest request,
  }) {
    final rawWords = responseData['words'] as List<dynamic>?;
    final words = rawWords
        ?.whereType<Map<String, dynamic>>()
        .map(_decodeWordTiming)
        .whereType<WordTiming>()
        .toList(growable: false);
    final normalizedText = words != null && words.isNotEmpty
        ? words.map((word) => word.word).join(' ')
        : responseData['text'] as String? ?? '';
    final languageProbability =
        (responseData['language_probability'] as num?)?.toDouble();

    return STTResponse(
      text: normalizedText,
      language: responseData['language_code'] as String?,
      confidence: languageProbability,
      words: words,
      model: request.model,
      duration: null,
      usage: null,
      languageProbability: languageProbability,
      additionalFormats:
          responseData['additional_formats'] as Map<String, dynamic>?,
    );
  }

  List<VoiceInfo> mapVoices(List<Map<String, dynamic>> rawVoices) {
    return rawVoices.map((voice) {
      final labels = voice['labels'];
      final labelsMap = labels is Map ? labels : null;

      return VoiceInfo(
        id: voice['voice_id'] as String? ?? '',
        name: voice['name'] as String? ?? '',
        description: voice['description'] as String?,
        category: voice['category'] as String?,
        gender: labelsMap?['gender'] as String?,
        accent: labelsMap?['accent'] as String?,
        previewUrl: voice['preview_url'] as String?,
      );
    }).toList(growable: false);
  }

  WordTiming? _decodeWordTiming(Map<String, dynamic> word) {
    final text = word['text'];
    final start = word['start'];
    final end = word['end'];
    if (text is! String || start is! num || end is! num) {
      return null;
    }

    return WordTiming(
      word: text,
      start: start.toDouble(),
      end: end.toDouble(),
      confidence: (word['logprob'] as num?)?.toDouble(),
    );
  }
}
