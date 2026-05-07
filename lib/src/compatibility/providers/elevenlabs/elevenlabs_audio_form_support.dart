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

  Map<String, dynamic> _buildSpeechToTextFieldMap({
    required STTRequest request,
    required String effectiveModel,
    required MultipartFile file,
  }) {
    final fields = <String, dynamic>{
      'file': file,
      'model_id': effectiveModel,
      'tag_audio_events': request.tagAudioEvents.toString(),
      'timestamps_granularity': request.timestampGranularity.name,
      'diarize': request.diarize.toString(),
    };

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
