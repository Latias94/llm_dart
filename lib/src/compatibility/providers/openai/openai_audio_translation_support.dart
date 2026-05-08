part of 'openai_audio_support.dart';

final class _OpenAIAudioTranslationSupport {
  static const _formSupport = _OpenAIAudioFormSupport();

  const _OpenAIAudioTranslationSupport();

  Future<FormData> buildTranslationFormData(
    AudioTranslationRequest request,
  ) async {
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
}
