part of 'openai_audio_support.dart';

final class _OpenAIAudioSpeechSupport {
  const _OpenAIAudioSpeechSupport();

  ({Map<String, dynamic> body, String voice, String contentType})
      buildSpeechRequest(
    TTSRequest request,
    OpenAIConfig config,
  ) {
    if (request.text.isEmpty) {
      throw const InvalidRequestError('Text input cannot be empty');
    }

    final audioConfig = config.audioCompat;
    final resolvedVoice = request.voice ?? audioConfig.defaultVoice;

    final requestBody = <String, dynamic>{
      'model': request.model ?? ProviderDefaults.openaiDefaultTTSModel,
      'input': request.text,
      'voice': resolvedVoice,
      if (request.format != null) 'response_format': request.format,
      if (request.speed != null) 'speed': request.speed,
    };

    return (
      body: requestBody,
      voice: resolvedVoice,
      contentType: _resolveSpeechContentType(request.format),
    );
  }

  TTSResponse buildSpeechResponse({
    required TTSRequest request,
    required List<int> audioData,
    required String voice,
    required String contentType,
  }) {
    return TTSResponse(
      audioData: audioData,
      contentType: contentType,
      voice: voice,
      model: request.model,
      duration: null,
      sampleRate: null,
      usage: null,
    );
  }

  String _resolveSpeechContentType(String? format) {
    return switch (format?.toLowerCase()) {
      'opus' => 'audio/opus',
      'aac' => 'audio/aac',
      'flac' => 'audio/flac',
      'wav' => 'audio/wav',
      'pcm' => 'audio/pcm',
      _ => 'audio/mpeg',
    };
  }
}
