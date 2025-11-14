import 'dart:async';
import 'dart:convert';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import 'client.dart';
import 'config.dart';

// ========== Google TTS Capability Interface ==========

/// Google-specific TTS capability interface
///
/// This interface provides Google Gemini's native text-to-speech capabilities
/// which differ from traditional TTS APIs by using chat-like interactions
/// with audio output modality.
///
/// **Key Features:**
/// - Controllable speech style through natural language prompts
/// - Single and multi-speaker support
/// - Voice configuration with prebuilt voices
/// - Streaming audio generation
/// - Integration with chat models for audio output
///
/// **Usage Example:**
/// ```dart
/// final googleProvider = await ai()
///     .google()
///     .apiKey(apiKey)
///     .model('gemini-2.5-flash-preview-tts')
///     .build();
///
/// if (googleProvider is GoogleTTSCapability) {
///   final response = await googleProvider.generateSpeech(
///     GoogleTTSRequest(
///       text: 'Say cheerfully: Have a wonderful day!',
///       voiceConfig: GoogleVoiceConfig.prebuilt('Kore'),
///     ),
///   );
///   // response.audioData contains the generated audio
/// }
/// ```
abstract class GoogleTTSCapability {
  /// Generate speech from text using Google's native TTS
  ///
  /// [request] - The TTS request configuration
  ///
  /// Returns audio data and metadata or throws an LLMError
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request);

  /// Generate speech with streaming output
  ///
  /// [request] - The TTS request configuration
  ///
  /// Returns a stream of audio events
  Stream<GoogleTTSStreamEvent> generateSpeechStream(GoogleTTSRequest request);

  /// Get available voices for Google TTS
  ///
  /// Returns a list of supported voice configurations
  Future<List<GoogleVoiceInfo>> getAvailableVoices();

  /// Get supported languages for Google TTS
  ///
  /// Returns a list of supported language codes
  Future<List<String>> getSupportedLanguages();

  /// Get predefined Google TTS voices
  ///
  /// Returns a list of all 30 prebuilt voices available in Google TTS
  static List<GoogleVoiceInfo> getPredefinedVoices() => [
        const GoogleVoiceInfo(name: 'Zephyr', description: 'Bright'),
        const GoogleVoiceInfo(name: 'Puck', description: 'Upbeat'),
        const GoogleVoiceInfo(name: 'Charon', description: 'Informative'),
        const GoogleVoiceInfo(name: 'Kore', description: 'Firm'),
        const GoogleVoiceInfo(name: 'Fenrir', description: 'Excitable'),
        const GoogleVoiceInfo(name: 'Leda', description: 'Youthful'),
        const GoogleVoiceInfo(name: 'Orus', description: 'Firm'),
        const GoogleVoiceInfo(name: 'Aoede', description: 'Breezy'),
        const GoogleVoiceInfo(name: 'Callirrhoe', description: 'Easy-going'),
        const GoogleVoiceInfo(name: 'Autonoe', description: 'Bright'),
        const GoogleVoiceInfo(name: 'Enceladus', description: 'Breathy'),
        const GoogleVoiceInfo(name: 'Iapetus', description: 'Clear'),
        const GoogleVoiceInfo(name: 'Umbriel', description: 'Easy-going'),
        const GoogleVoiceInfo(name: 'Algieba', description: 'Smooth'),
        const GoogleVoiceInfo(name: 'Despina', description: 'Smooth'),
        const GoogleVoiceInfo(name: 'Erinome', description: 'Clear'),
        const GoogleVoiceInfo(name: 'Algenib', description: 'Gravelly'),
        const GoogleVoiceInfo(name: 'Rasalgethi', description: 'Informative'),
        const GoogleVoiceInfo(name: 'Laomedeia', description: 'Upbeat'),
        const GoogleVoiceInfo(name: 'Achernar', description: 'Soft'),
        const GoogleVoiceInfo(name: 'Alnilam', description: 'Firm'),
        const GoogleVoiceInfo(name: 'Schedar', description: 'Even'),
        const GoogleVoiceInfo(name: 'Gacrux', description: 'Mature'),
        const GoogleVoiceInfo(name: 'Pulcherrima', description: 'Forward'),
        const GoogleVoiceInfo(name: 'Achird', description: 'Friendly'),
        const GoogleVoiceInfo(name: 'Zubenelgenubi', description: 'Casual'),
        const GoogleVoiceInfo(name: 'Vindemiatrix', description: 'Gentle'),
        const GoogleVoiceInfo(name: 'Sadachbia', description: 'Lively'),
        const GoogleVoiceInfo(name: 'Sadaltager', description: 'Knowledgeable'),
        const GoogleVoiceInfo(name: 'Sulafat', description: 'Warm'),
      ];

  /// Get supported languages for Google TTS
  ///
  /// Returns a list of all 24 supported language codes
  static List<String> getSupportedLanguageCodes() => [
        'ar-EG', // Arabic (Egyptian)
        'de-DE', // German (Germany)
        'en-US', // English (US)
        'es-US', // Spanish (US)
        'fr-FR', // French (France)
        'hi-IN', // Hindi (India)
        'id-ID', // Indonesian (Indonesia)
        'it-IT', // Italian (Italy)
        'ja-JP', // Japanese (Japan)
        'ko-KR', // Korean (Korea)
        'pt-BR', // Portuguese (Brazil)
        'ru-RU', // Russian (Russia)
        'nl-NL', // Dutch (Netherlands)
        'pl-PL', // Polish (Poland)
        'th-TH', // Thai (Thailand)
        'tr-TR', // Turkish (Turkey)
        'vi-VN', // Vietnamese (Vietnam)
        'ro-RO', // Romanian (Romania)
        'uk-UA', // Ukrainian (Ukraine)
        'bn-BD', // Bengali (Bangladesh)
        'en-IN', // English (India) & Hindi (India) bundle
        'mr-IN', // Marathi (India)
        'ta-IN', // Tamil (India)
        'te-IN', // Telugu (India)
      ];
}

// ========== Google TTS Models ==========

/// Google TTS request configuration
///
/// This class represents a request for Google's native text-to-speech API
/// which uses chat-like interactions with audio output modality.
class GoogleTTSRequest {
  /// Text content to convert to speech
  final String text;

  /// Voice configuration for single speaker
  final GoogleVoiceConfig? voiceConfig;

  /// Multi-speaker voice configuration
  final GoogleMultiSpeakerVoiceConfig? multiSpeakerVoiceConfig;

  /// Model to use (e.g., 'gemini-2.5-flash-preview-tts')
  final String? model;

  /// Additional generation configuration
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

  /// Create a single-speaker TTS request
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

  /// Create a multi-speaker TTS request
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
              {'text': text}
            ]
          }
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

/// Google voice configuration for single speaker
class GoogleVoiceConfig {
  /// Prebuilt voice configuration
  final GooglePrebuiltVoiceConfig? prebuiltVoiceConfig;

  const GoogleVoiceConfig({this.prebuiltVoiceConfig});

  /// Create a prebuilt voice configuration
  factory GoogleVoiceConfig.prebuilt(String voiceName) => GoogleVoiceConfig(
        prebuiltVoiceConfig: GooglePrebuiltVoiceConfig(voiceName: voiceName),
      );

  Map<String, dynamic> toJson() => {
        if (prebuiltVoiceConfig != null)
          'prebuiltVoiceConfig': prebuiltVoiceConfig!.toJson(),
      };
}

/// Google prebuilt voice configuration
class GooglePrebuiltVoiceConfig {
  /// Voice name (e.g., 'Kore', 'Puck', 'Zephyr')
  final String voiceName;

  const GooglePrebuiltVoiceConfig({required this.voiceName});

  Map<String, dynamic> toJson() => {'voiceName': voiceName};
}

/// Google multi-speaker voice configuration
class GoogleMultiSpeakerVoiceConfig {
  /// List of speaker voice configurations
  final List<GoogleSpeakerVoiceConfig> speakerVoiceConfigs;

  const GoogleMultiSpeakerVoiceConfig(this.speakerVoiceConfigs);

  Map<String, dynamic> toJson() => {
        'speakerVoiceConfigs':
            speakerVoiceConfigs.map((config) => config.toJson()).toList(),
      };
}

/// Google speaker voice configuration for multi-speaker TTS
class GoogleSpeakerVoiceConfig {
  /// Speaker name (must match names used in the text)
  final String speaker;

  /// Voice configuration for this speaker
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

/// Google TTS response
class GoogleTTSResponse {
  /// Generated audio data as bytes
  final List<int> audioData;

  /// Content type (e.g., 'audio/pcm')
  final String? contentType;

  /// Usage information if available
  final UsageInfo? usage;

  /// Model used for generation
  final String? model;

  /// Additional metadata from the response
  final Map<String, dynamic>? metadata;

  const GoogleTTSResponse({
    required this.audioData,
    this.contentType,
    this.usage,
    this.model,
    this.metadata,
  });

  /// Create response from Google API response
  factory GoogleTTSResponse.fromApiResponse(Map<String, dynamic> response) {
    final candidate = response['candidates']?[0];
    final content = candidate?['content'];
    final parts = content?['parts'];
    final inlineData = parts?[0]?['inlineData'];
    final data = inlineData?['data'] as String?;

    if (data == null) {
      throw ArgumentError('No audio data found in response');
    }

    // Decode base64 audio data
    final audioBytes = base64Decode(data);

    return GoogleTTSResponse(
      audioData: audioBytes,
      contentType: inlineData?['mimeType'] as String?,
      usage: response['usageMetadata'] != null
          ? _parseUsageInfo(response['usageMetadata'] as Map<String, dynamic>)
          : null,
      model: response['modelVersion'] as String?,
      metadata: response,
    );
  }

  /// Parse Google's usage metadata format to UsageInfo
  static UsageInfo _parseUsageInfo(Map<String, dynamic> usageMetadata) {
    return UsageInfo(
      promptTokens: usageMetadata['promptTokenCount'] as int?,
      completionTokens: usageMetadata['candidatesTokenCount'] as int?,
      totalTokens: usageMetadata['totalTokenCount'] as int?,
    );
  }
}

/// Google voice information
class GoogleVoiceInfo {
  /// Voice name
  final String name;

  /// Voice description
  final String description;

  /// Voice category (e.g., 'Bright', 'Upbeat', 'Informative')
  final String? category;

  /// Whether this voice supports multi-speaker scenarios
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

/// Google TTS stream events
abstract class GoogleTTSStreamEvent {
  const GoogleTTSStreamEvent();
}

/// Google TTS audio data event
class GoogleTTSAudioDataEvent extends GoogleTTSStreamEvent {
  /// Audio data chunk
  final List<int> data;

  /// Whether this is the final chunk
  final bool isFinal;

  const GoogleTTSAudioDataEvent({
    required this.data,
    this.isFinal = false,
  });
}

/// Google TTS metadata event
class GoogleTTSMetadataEvent extends GoogleTTSStreamEvent {
  /// Content type
  final String? contentType;

  /// Model used
  final String? model;

  /// Usage information
  final UsageInfo? usage;

  const GoogleTTSMetadataEvent({
    this.contentType,
    this.model,
    this.usage,
  });
}

/// Google TTS error event
class GoogleTTSErrorEvent extends GoogleTTSStreamEvent {
  /// Error message
  final String message;

  /// Error code if available
  final String? code;

  const GoogleTTSErrorEvent({
    required this.message,
    this.code,
  });
}

/// Google TTS completion event
class GoogleTTSCompletionEvent extends GoogleTTSStreamEvent {
  /// Complete response
  final GoogleTTSResponse response;

  const GoogleTTSCompletionEvent(this.response);
}

/// Google TTS implementation
///
/// This class implements Google's native text-to-speech capabilities
/// using the Gemini API with audio output modality.
class GoogleTTS implements GoogleTTSCapability {
  final GoogleClient _client;
  final GoogleConfig _config;

  GoogleTTS(this._client, this._config);

  @override
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request) async {
    try {
      final requestBody = request.toJson();

      // Use the appropriate TTS model if not specified
      final model = request.model ?? _config.model;

      final response = await _client.post(
        'models/$model:generateContent',
        data: requestBody,
      );

      return GoogleTTSResponse.fromApiResponse(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw GenericError('Google TTS generation failed: $e');
    }
  }

  @override
  Stream<GoogleTTSStreamEvent> generateSpeechStream(
      GoogleTTSRequest request) async* {
    try {
      final requestBody = request.toJson();

      // Use the appropriate TTS model if not specified
      final model = request.model ?? _config.model;

      final stream = _client.postStream(
        'models/$model:streamGenerateContent',
        data: requestBody,
      );

      await for (final chunk in stream) {
        try {
          final data = chunk.data;
          if (data is Map<String, dynamic>) {
            // Check if this chunk contains audio data
            final candidate = data['candidates']?[0];
            final content = candidate?['content'];
            final parts = content?['parts'];
            final inlineData = parts?[0]?['inlineData'];
            final audioData = inlineData?['data'] as String?;

            if (audioData != null) {
              // Decode base64 audio data
              final audioBytes = base64.decode(audioData);
              yield GoogleTTSAudioDataEvent(data: audioBytes);
            }

            // Check for completion
            if (candidate?['finishReason'] != null) {
              final response = GoogleTTSResponse.fromApiResponse(data);
              yield GoogleTTSCompletionEvent(response);
            }
          }
        } catch (e) {
          yield GoogleTTSErrorEvent(
              message: 'Error processing stream chunk: $e');
        }
      }
    } catch (e) {
      yield GoogleTTSErrorEvent(message: 'Google TTS streaming failed: $e');
    }
  }

  @override
  Future<List<GoogleVoiceInfo>> getAvailableVoices() async {
    // Return the predefined voices since Google doesn't provide a voices API
    return GoogleTTSCapability.getPredefinedVoices();
  }

  @override
  Future<List<String>> getSupportedLanguages() async {
    // Return the supported language codes
    return GoogleTTSCapability.getSupportedLanguageCodes();
  }

  /// Check if the current model supports TTS
  bool get supportsTTS {
    final model = _config.model;
    return model.contains('tts') || model.contains('gemini-2.5');
  }

  /// Get the default TTS model
  String get defaultTTSModel => 'gemini-2.5-flash-preview-tts';

  /// Create a simple TTS request
  GoogleTTSRequest createSimpleRequest({
    required String text,
    String voiceName = 'Kore',
    String? model,
  }) {
    return GoogleTTSRequest.singleSpeaker(
      text: text,
      voiceName: voiceName,
      model: model ?? defaultTTSModel,
    );
  }

  /// Create a multi-speaker TTS request
  GoogleTTSRequest createMultiSpeakerRequest({
    required String text,
    required Map<String, String> speakerVoices,
    String? model,
  }) {
    final speakers = speakerVoices.entries
        .map((entry) => GoogleSpeakerVoiceConfig(
              speaker: entry.key,
              voiceConfig: GoogleVoiceConfig.prebuilt(entry.value),
            ))
        .toList();

    return GoogleTTSRequest.multiSpeaker(
      text: text,
      speakers: speakers,
      model: model ?? defaultTTSModel,
    );
  }
}
