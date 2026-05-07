part of 'google_tts_models.dart';

/// Google TTS request configuration.
class GoogleTTSRequest {
  /// Text content to convert to speech.
  final String text;

  /// Voice configuration for single speaker.
  final GoogleVoiceConfig? voiceConfig;

  /// Multi-speaker voice configuration.
  final GoogleMultiSpeakerVoiceConfig? multiSpeakerVoiceConfig;

  /// Model to use (for example, `gemini-2.5-flash-preview-tts`).
  final String? model;

  /// Additional generation configuration.
  final Map<String, dynamic>? generationConfig;

  const GoogleTTSRequest({
    required this.text,
    this.voiceConfig,
    this.multiSpeakerVoiceConfig,
    this.model,
    this.generationConfig,
  }) : assert(
          voiceConfig != null || multiSpeakerVoiceConfig != null,
          'Either voiceConfig or multiSpeakerVoiceConfig must be provided',
        );

  /// Create a single-speaker TTS request.
  factory GoogleTTSRequest.singleSpeaker({
    required String text,
    required String voiceName,
    String? model,
    Map<String, dynamic>? generationConfig,
  }) =>
      GoogleTTSRequest(
        text: text,
        voiceConfig: GoogleVoiceConfig.prebuilt(voiceName),
        model: model,
        generationConfig: generationConfig,
      );

  /// Create a multi-speaker TTS request.
  factory GoogleTTSRequest.multiSpeaker({
    required String text,
    required List<GoogleSpeakerVoiceConfig> speakers,
    String? model,
    Map<String, dynamic>? generationConfig,
  }) =>
      GoogleTTSRequest(
        text: text,
        multiSpeakerVoiceConfig: GoogleMultiSpeakerVoiceConfig(speakers),
        model: model,
        generationConfig: generationConfig,
      );

  Map<String, dynamic> toJson() => {
        'contents': [
          {
            'parts': [
              {'text': text},
            ],
          },
        ],
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': _buildSpeechConfig(),
          if (generationConfig != null) ...generationConfig!,
        },
        if (model != null) 'model': model,
      };

  Map<String, dynamic> _buildSpeechConfig() {
    if (voiceConfig != null) {
      return {'voiceConfig': voiceConfig!.toJson()};
    } else if (multiSpeakerVoiceConfig != null) {
      return {'multiSpeakerVoiceConfig': multiSpeakerVoiceConfig!.toJson()};
    }

    throw StateError('No voice configuration provided');
  }
}

/// Google voice configuration for single speaker.
class GoogleVoiceConfig {
  /// Prebuilt voice configuration.
  final GooglePrebuiltVoiceConfig? prebuiltVoiceConfig;

  const GoogleVoiceConfig({this.prebuiltVoiceConfig});

  /// Create a prebuilt voice configuration.
  factory GoogleVoiceConfig.prebuilt(String voiceName) => GoogleVoiceConfig(
        prebuiltVoiceConfig: GooglePrebuiltVoiceConfig(voiceName: voiceName),
      );

  Map<String, dynamic> toJson() => {
        if (prebuiltVoiceConfig != null)
          'prebuiltVoiceConfig': prebuiltVoiceConfig!.toJson(),
      };
}

/// Google prebuilt voice configuration.
class GooglePrebuiltVoiceConfig {
  /// Voice name (for example, `Kore`, `Puck`, or `Zephyr`).
  final String voiceName;

  const GooglePrebuiltVoiceConfig({required this.voiceName});

  Map<String, dynamic> toJson() => {'voiceName': voiceName};
}

/// Google multi-speaker voice configuration.
class GoogleMultiSpeakerVoiceConfig {
  /// List of speaker voice configurations.
  final List<GoogleSpeakerVoiceConfig> speakerVoiceConfigs;

  const GoogleMultiSpeakerVoiceConfig(this.speakerVoiceConfigs);

  Map<String, dynamic> toJson() => {
        'speakerVoiceConfigs':
            speakerVoiceConfigs.map((config) => config.toJson()).toList(),
      };
}

/// Google speaker voice configuration for multi-speaker TTS.
class GoogleSpeakerVoiceConfig {
  /// Speaker name. Must match names used in the text.
  final String speaker;

  /// Voice configuration for this speaker.
  final GoogleVoiceConfig voiceConfig;

  const GoogleSpeakerVoiceConfig({
    required this.speaker,
    required this.voiceConfig,
  });

  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'voiceConfig': voiceConfig.toJson(),
      };
}
