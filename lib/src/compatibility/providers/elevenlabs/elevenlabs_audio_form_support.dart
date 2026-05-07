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
    final fields = <String, dynamic>{
      'model_id': effectiveModel,
      'tag_audio_events': request.tagAudioEvents.toString(),
      'timestamps_granularity': request.timestampGranularity.name,
      'diarize': request.diarize.toString(),
    };

    if (file != null) {
      fields['file'] = file;
    }
    if (sourceUrl != null) {
      fields['source_url'] = sourceUrl;
    }

    if (request.language != null) {
      fields['language_code'] = request.language;
    }
    if (request.numSpeakers != null) {
      fields['num_speakers'] = request.numSpeakers.toString();
    }
    if (request.format != null) {
      fields['file_format'] = request.format;
    }

    return fields;
  }
}
