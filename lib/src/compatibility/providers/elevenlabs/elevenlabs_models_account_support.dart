part of 'elevenlabs_models_compat.dart';

extension ElevenLabsModelsAccountSupport on ElevenLabsModels {
  Future<List<Map<String, dynamic>>> getModels() async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    try {
      final models = await client.getList('models');
      return models.cast<Map<String, dynamic>>();
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    try {
      return await client.getJson('user');
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error: $e');
    }
  }
}
