part of 'tts.dart';

final class _GoogleTTSSpeechSupport {
  const _GoogleTTSSpeechSupport();

  Future<GoogleTTSResponse> generateSpeech({
    required GoogleClient client,
    required GoogleConfig config,
    required _GoogleTTSRequestSupport requestSupport,
    required GoogleTTSRequest request,
  }) async {
    try {
      final requestBody = request.toJson();
      final model = requestSupport.resolveModel(request, config);

      final response = await client.post(
        requestSupport.generateContentEndpoint(model),
        data: requestBody,
      );

      return GoogleTTSResponse.fromApiResponse(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw GenericError('Google TTS generation failed: $e');
    }
  }
}
