import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../models/audio_models.dart';
import '../../../config/provider_defaults.dart';
import '../../../../providers/openai/config.dart';
import 'config_views.dart';

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

  Future<FormData> buildTranscriptionFormData(STTRequest request) async {
    if (request.audioData == null && request.filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }

    final formData = FormData();
    await _attachAudioFile(
      formData: formData,
      audioData: request.audioData,
      filePath: request.filePath,
      format: request.format,
    );

    formData.fields.add(
      MapEntry(
          'model', request.model ?? ProviderDefaults.openaiDefaultSTTModel),
    );
    if (request.language != null) {
      formData.fields.add(MapEntry('language', request.language!));
    }
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

    for (final granularity in _resolveTimestampGranularities(request)) {
      formData.fields.add(MapEntry('timestamp_granularities[]', granularity));
    }

    return formData;
  }

  STTResponse buildTranscriptionResponse(
    STTRequest request,
    Map<String, dynamic> responseData,
  ) {
    List<WordTiming>? words;
    if ((request.includeWordTiming ||
            request.timestampGranularity == TimestampGranularity.word) &&
        responseData['words'] != null) {
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
    );
  }

  Future<FormData> buildTranslationFormData(
    AudioTranslationRequest request,
  ) async {
    if (request.audioData == null && request.filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }

    final formData = FormData();
    await _attachAudioFile(
      formData: formData,
      audioData: request.audioData,
      filePath: request.filePath,
      format: request.format,
    );

    formData.fields.add(
      MapEntry(
          'model', request.model ?? ProviderDefaults.openaiDefaultSTTModel),
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

  List<String> _resolveTimestampGranularities(STTRequest request) {
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
}
