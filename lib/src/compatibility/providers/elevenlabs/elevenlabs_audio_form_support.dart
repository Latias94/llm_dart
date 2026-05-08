part of 'elevenlabs_audio_support.dart';

final class _ElevenLabsAudioFormSupport {
  const _ElevenLabsAudioFormSupport();

  Future<FormData> buildSpeechToTextFormDataFromBytes(
    List<int> audioData, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return FormData.fromMap(
      _buildSpeechToTextFieldMap(
        request: request,
        effectiveModel: effectiveModel,
        file: MultipartFile.fromBytes(
          Uint8List.fromList(audioData),
          filename: 'audio.wav',
          contentType: DioMediaType('audio', 'wav'),
        ),
      ),
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromFile(
    String filePath, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return FormData.fromMap(
      _buildSpeechToTextFieldMap(
        request: request,
        effectiveModel: effectiveModel,
        file: await MultipartFile.fromFile(filePath),
      ),
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromSourceUrl(
    String sourceUrl, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return FormData.fromMap(
      _buildSpeechToTextFieldMap(
        request: request,
        effectiveModel: effectiveModel,
        sourceUrl: sourceUrl,
      ),
    );
  }

  Map<String, dynamic> _buildSpeechToTextFieldMap({
    required STTRequest request,
    required String effectiveModel,
    MultipartFile? file,
    String? sourceUrl,
  }) {
    final options = _resolveElevenLabsTranscriptionOptions(
      request.providerOptions,
    );
    final timestampGranularity = options?.timestampGranularity?.name ??
        request.timestampGranularity.name;
    final fields = <String, dynamic>{
      'model_id': effectiveModel,
      'timestamps_granularity': timestampGranularity,
    };
    final tagAudioEvents = options?.tagAudioEvents;
    if (tagAudioEvents != null) {
      fields['tag_audio_events'] = tagAudioEvents.toString();
    }
    final diarize = options?.diarize;
    if (diarize != null) {
      fields['diarize'] = diarize.toString();
    }

    if (file != null) {
      fields['file'] = file;
    }
    if (sourceUrl != null) {
      fields['source_url'] = sourceUrl;
    }

    final languageCode = options?.languageCode ?? request.language;
    if (languageCode != null) {
      fields['language_code'] = languageCode;
    }
    final numSpeakers = options?.numSpeakers;
    if (numSpeakers != null) {
      fields['num_speakers'] = numSpeakers.toString();
    }
    final fileFormat = options?.fileFormat?.value ?? request.format;
    if (fileFormat != null) {
      fields['file_format'] = fileFormat;
    }

    return fields;
  }
}
