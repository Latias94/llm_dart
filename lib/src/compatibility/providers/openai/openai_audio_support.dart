import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' show ProviderMetadata;
import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../models/audio_models.dart';
import '../../../../providers/openai/config.dart';
import 'config_views.dart';
import 'openai_audio_catalog.dart';
import 'openai_audio_translation_models.dart';

/// Request/response helpers for the OpenAI compatibility audio facade.
class OpenAIAudioSupport {
  final OpenAIConfig config;

  OpenAIAudioSupport(this.config);

  ({Map<String, dynamic> body, String voice, String contentType})
      buildSpeechRequest(TTSRequest request) {
    if (request.text.isEmpty) {
      throw const InvalidRequestError('Text input cannot be empty');
    }

    final audioConfig = config.audioCompat;
    final resolvedVoice = request.voice ?? audioConfig.defaultVoice;
    final options = _resolveOpenAISpeechOptions(request.providerOptions);
    final outputFormat = options?.outputFormat ?? request.format;
    final speed = options?.speed ?? request.speed;
    final instructions = options?.instructions;
    final language = options?.language ?? request.languageCode;

    final requestBody = <String, dynamic>{
      'model': request.model ?? OpenAIAudioCatalog.defaultTtsModel,
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

  Future<FormData> buildTranscriptionFormData(STTRequest request) async {
    final options = _resolveOpenAITranscriptionOptions(
      request.providerOptions,
    );
    _validateAudioSource(
      audioData: request.audioData,
      filePath: request.filePath,
    );

    final formData = FormData();
    await _attachAudioFile(
      formData: formData,
      audioData: request.audioData,
      filePath: request.filePath,
      format: request.format,
    );

    formData.fields.add(
      MapEntry(
        'model',
        request.model ?? OpenAIAudioCatalog.defaultSttModel,
      ),
    );
    final language = options?.language ?? request.language;
    if (language != null) {
      formData.fields.add(MapEntry('language', language));
    }
    final prompt = options?.prompt;
    if (prompt != null) {
      formData.fields.add(MapEntry('prompt', prompt));
    }
    final responseFormat = options?.responseFormat?.value;
    if (responseFormat != null) {
      formData.fields.add(MapEntry('response_format', responseFormat));
    }
    final temperature = options?.temperature;
    if (temperature != null) {
      formData.fields.add(
        MapEntry('temperature', temperature.toString()),
      );
    }

    for (final granularity in _resolveTimestampGranularities(
      request,
      options,
    )) {
      formData.fields.add(MapEntry('timestamp_granularities[]', granularity));
    }

    return formData;
  }

  STTResponse buildTranscriptionResponse(
    STTRequest request,
    Map<String, dynamic> responseData,
  ) {
    final options = _resolveOpenAITranscriptionOptions(
      request.providerOptions,
    );
    List<WordTiming>? words;
    if (_shouldDecodeWords(request, options) && responseData['words'] != null) {
      final wordsData = responseData['words'] as List;
      words = wordsData.map((word) {
        final wordMap = word as Map<String, dynamic>;
        return WordTiming(
          word: wordMap['word'] as String,
          start: (wordMap['start'] as num).toDouble(),
          end: (wordMap['end'] as num).toDouble(),
          confidence: null,
        );
      }).toList();
    }

    return STTResponse(
      text: responseData['text'] as String,
      language: responseData['language'] as String?,
      confidence: null,
      words: words,
      model: request.model,
      duration: responseData['duration'] as double?,
      usage: null,
      providerMetadata: ProviderMetadata.forNamespace(
        'openai',
        {
          if (responseData['language'] != null)
            'language': responseData['language'],
          if (responseData['duration'] != null)
            'durationSeconds': responseData['duration'],
          if (responseData['words'] != null) 'words': responseData['words'],
          if (responseData['segments'] != null)
            'segments': responseData['segments'],
        },
      ),
    );
  }

  Future<FormData> buildTranslationFormData(
    AudioTranslationRequest request,
  ) async {
    _validateAudioSource(
      audioData: request.audioData,
      filePath: request.filePath,
    );

    final formData = FormData();
    await _attachAudioFile(
      formData: formData,
      audioData: request.audioData,
      filePath: request.filePath,
      format: request.format,
    );

    formData.fields.add(
      MapEntry(
        'model',
        request.model ?? OpenAIAudioCatalog.defaultSttModel,
      ),
    );
    if (request.prompt != null) {
      formData.fields.add(MapEntry('prompt', request.prompt!));
    }
    if (request.responseFormat != null) {
      formData.fields.add(MapEntry('response_format', request.responseFormat!));
    }
    if (request.temperature != null) {
      formData.fields.add(
        MapEntry('temperature', request.temperature.toString()),
      );
    }

    return formData;
  }

  STTResponse buildTranslationResponse(
    AudioTranslationRequest request,
    Map<String, dynamic> responseData,
  ) {
    return STTResponse(
      text: responseData['text'] as String,
      language: 'en',
      confidence: null,
      words: null,
      model: request.model,
      duration: responseData['duration'] as double?,
      usage: null,
      providerMetadata: ProviderMetadata.forNamespace(
        'openai',
        {
          'endpoint': 'audio.translations',
          if (responseData['duration'] != null)
            'durationSeconds': responseData['duration'],
        },
      ),
    );
  }

  void _validateAudioSource({
    required List<int>? audioData,
    required String? filePath,
  }) {
    if (audioData == null && filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }
  }

  Future<void> _attachAudioFile({
    required FormData formData,
    required List<int>? audioData,
    required String? filePath,
    required String? format,
  }) async {
    if (audioData != null) {
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            audioData,
            filename: 'audio.${format ?? 'wav'}',
          ),
        ),
      );
      return;
    }

    if (filePath != null) {
      formData.files.add(
        MapEntry('file', await MultipartFile.fromFile(filePath)),
      );
    }
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

  bool _shouldDecodeWords(
    STTRequest request,
    modern_openai.OpenAITranscriptionOptions? options,
  ) {
    return request.includeWordTiming ||
        request.timestampGranularity == TimestampGranularity.word ||
        (options?.timestampGranularities.contains(
              modern_openai.OpenAITranscriptionTimestampGranularity.word,
            ) ??
            false);
  }

  List<String> _resolveTimestampGranularities(
    STTRequest request,
    modern_openai.OpenAITranscriptionOptions? options,
  ) {
    if (options != null && options.timestampGranularities.isNotEmpty) {
      return options.timestampGranularities
          .map((granularity) => granularity.value)
          .toList(growable: false);
    }

    final granularities = <String>[];
    if (request.includeWordTiming ||
        request.timestampGranularity == TimestampGranularity.word) {
      granularities.add('word');
    }
    if (request.timestampGranularity == TimestampGranularity.segment) {
      granularities.add('segment');
    }
    return granularities;
  }

  modern_openai.OpenAITranscriptionOptions? _resolveOpenAITranscriptionOptions(
    Object? options,
  ) {
    if (options == null) {
      return null;
    }
    if (options is modern_openai.OpenAITranscriptionOptions) {
      return options;
    }
    throw ArgumentError.value(
      options,
      'providerOptions',
      'Expected OpenAITranscriptionOptions for OpenAI transcription requests.',
    );
  }
}
