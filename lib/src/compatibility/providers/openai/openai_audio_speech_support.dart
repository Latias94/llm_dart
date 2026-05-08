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
    final options = _resolveOpenAISpeechOptions(request.providerOptions);
    final outputFormat = options?.outputFormat ?? request.format;
    final speed = options?.speed ?? request.speed;
    final instructions = options?.instructions ?? request.instructions;
    final language = options?.language ?? request.languageCode;

    final requestBody = <String, dynamic>{
      'model': request.model ?? ProviderDefaults.openaiDefaultTTSModel,
      'input': request.text,
      'voice': resolvedVoice,
      if (outputFormat != null) 'response_format': outputFormat,
      if (instructions != null) 'instructions': instructions,
      if (speed != null) 'speed': speed,
      if (language != null) 'language': language,
    };

    return (
      body: requestBody,
      voice: resolvedVoice,
      contentType: _resolveSpeechContentType(outputFormat),
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

  modern_openai.OpenAISpeechOptions? _resolveOpenAISpeechOptions(
    Object? options,
  ) {
    if (options == null) {
      return null;
    }
    if (options is modern_openai.OpenAISpeechOptions) {
      return options;
    }
    throw ArgumentError.value(
      options,
      'providerOptions',
      'Expected OpenAISpeechOptions for OpenAI text-to-speech requests.',
    );
  }
}
