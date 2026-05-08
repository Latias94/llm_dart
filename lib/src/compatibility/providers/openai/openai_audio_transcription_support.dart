part of 'openai_audio_support.dart';

final class _OpenAIAudioTranscriptionSupport {
  static const _formSupport = _OpenAIAudioFormSupport();

  const _OpenAIAudioTranscriptionSupport();

  Future<FormData> buildTranscriptionFormData(STTRequest request) async {
    final options = _resolveOpenAITranscriptionOptions(
      request.providerOptions,
    );
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
    final language = options?.language ?? request.language;
    if (language != null) {
      formData.fields.add(MapEntry('language', language));
    }
    final prompt = options?.prompt ?? request.prompt;
    if (prompt != null) {
      formData.fields.add(MapEntry('prompt', prompt));
    }
    final responseFormat =
        options?.responseFormat?.value ?? request.responseFormat;
    if (responseFormat != null) {
      formData.fields.add(MapEntry('response_format', responseFormat));
    }
    final temperature = options?.temperature ?? request.temperature;
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
      Object? options) {
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
