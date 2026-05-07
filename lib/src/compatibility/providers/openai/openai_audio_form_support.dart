part of 'openai_audio_support.dart';

final class _OpenAIAudioFormSupport {
  const _OpenAIAudioFormSupport();

  void validateAudioSource({
    required List<int>? audioData,
    required String? filePath,
  }) {
    if (audioData == null && filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }
  }

  Future<void> attachAudioFile({
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
