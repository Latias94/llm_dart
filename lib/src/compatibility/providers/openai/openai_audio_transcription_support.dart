part of 'openai_audio_support.dart';

final class _OpenAIAudioTranscriptionSupport {
  static const _formSupport = _OpenAIAudioFormSupport();

  const _OpenAIAudioTranscriptionSupport();

  Future<FormData> buildTranscriptionFormData(STTRequest request) async {
    _formSupport.validateAudioSource(
      audioData: request.audioData,
      filePath: request.filePath,
    );

    final formData = FormData();
    await _formSupport.attachAudioFile(
      formData: formData,
      audioData: request.audioData,
      filePath: request.filePath,
      format: request.format,
    );

    formData.fields.add(
      MapEntry(
        'model',
        request.model ?? ProviderDefaults.openaiDefaultSTTModel,
      ),
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
}
