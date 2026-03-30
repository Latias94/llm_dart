/// Google Gemini native TTS models and events.
library;

import 'dart:convert';

import 'usage_models.dart';

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

/// Google TTS response.
class GoogleTTSResponse {
  /// Generated audio data as bytes.
  final List<int> audioData;

  /// Content type (for example, `audio/pcm`).
  final String? contentType;

  /// Usage information if available.
  final UsageInfo? usage;

  /// Model used for generation.
  final String? model;

  /// Additional metadata from the response.
  final Map<String, dynamic>? metadata;

  const GoogleTTSResponse({
    required this.audioData,
    this.contentType,
    this.usage,
    this.model,
    this.metadata,
  });

  /// Create a response from the Google API response payload.
  factory GoogleTTSResponse.fromApiResponse(Map<String, dynamic> response) {
    final candidate = response['candidates']?[0];
    final content = candidate?['content'];
    final parts = content?['parts'];
    final inlineData = parts?[0]?['inlineData'];
    final data = inlineData?['data'] as String?;

    if (data == null) {
      throw ArgumentError('No audio data found in response');
    }

    return GoogleTTSResponse(
      audioData: base64Decode(data),
      contentType: inlineData?['mimeType'] as String?,
      usage: response['usageMetadata'] != null
          ? _parseUsageInfo(response['usageMetadata'] as Map<String, dynamic>)
          : null,
      model: response['modelVersion'] as String?,
      metadata: response,
    );
  }

  static UsageInfo _parseUsageInfo(Map<String, dynamic> usageMetadata) {
    return UsageInfo(
      promptTokens: usageMetadata['promptTokenCount'] as int?,
      completionTokens: usageMetadata['candidatesTokenCount'] as int?,
      totalTokens: usageMetadata['totalTokenCount'] as int?,
    );
  }
}

/// Google voice information.
class GoogleVoiceInfo {
  /// Voice name.
  final String name;

  /// Voice description.
  final String description;

  /// Voice category (for example, `Bright` or `Upbeat`).
  final String? category;

  /// Whether this voice supports multi-speaker scenarios.
  final bool supportsMultiSpeaker;

  const GoogleVoiceInfo({
    required this.name,
    required this.description,
    this.category,
    this.supportsMultiSpeaker = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (category != null) 'category': category,
        'supports_multi_speaker': supportsMultiSpeaker,
      };

  factory GoogleVoiceInfo.fromJson(Map<String, dynamic> json) =>
      GoogleVoiceInfo(
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String?,
        supportsMultiSpeaker: json['supports_multi_speaker'] as bool? ?? true,
      );
}

/// Google TTS stream event base type.
abstract class GoogleTTSStreamEvent {
  const GoogleTTSStreamEvent();
}

/// Google TTS audio data event.
class GoogleTTSAudioDataEvent extends GoogleTTSStreamEvent {
  /// Audio data chunk.
  final List<int> data;

  /// Whether this is the final chunk.
  final bool isFinal;

  const GoogleTTSAudioDataEvent({
    required this.data,
    this.isFinal = false,
  });
}

/// Google TTS metadata event.
class GoogleTTSMetadataEvent extends GoogleTTSStreamEvent {
  /// Content type.
  final String? contentType;

  /// Model used.
  final String? model;

  /// Usage information.
  final UsageInfo? usage;

  const GoogleTTSMetadataEvent({
    this.contentType,
    this.model,
    this.usage,
  });
}

/// Google TTS error event.
class GoogleTTSErrorEvent extends GoogleTTSStreamEvent {
  /// Error message.
  final String message;

  /// Error code if available.
  final String? code;

  const GoogleTTSErrorEvent({
    required this.message,
    this.code,
  });
}

/// Google TTS completion event.
class GoogleTTSCompletionEvent extends GoogleTTSStreamEvent {
  /// Complete response.
  final GoogleTTSResponse response;

  const GoogleTTSCompletionEvent(this.response);
}
