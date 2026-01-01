import 'package:llm_dart_core/llm_dart_core.dart';

import 'client.dart';
import 'config.dart';

/// ElevenLabs Models capability implementation.
class ElevenLabsModels {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;

  ElevenLabsModels(this.client, this.config);

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

  Future<Map<String, dynamic>?> getModelInfo(String modelId) async {
    final models = await getModels();
    for (final model in models) {
      if (model['model_id'] == modelId) return model;
    }
    return null;
  }

  Future<bool> modelSupportsTTS(String modelId) async {
    final modelInfo = await getModelInfo(modelId);
    if (modelInfo == null) return false;
    final canDoTTS = modelInfo['can_do_text_to_speech'] as bool?;
    return canDoTTS ?? false;
  }

  Future<bool> modelSupportsSTT(String modelId) async {
    final modelInfo = await getModelInfo(modelId);
    if (modelInfo == null) return false;
    final canDoSTT = modelInfo['can_do_voice_conversion'] as bool?;
    return canDoSTT ?? false;
  }

  Future<List<String>> getRecommendedTTSModels() async {
    final models = await getModels();
    final ttsModels = <String>[];

    for (final model in models) {
      final canDoTTS = model['can_do_text_to_speech'] as bool?;
      if (canDoTTS == true) {
        final modelId = model['model_id'] as String?;
        if (modelId != null) ttsModels.add(modelId);
      }
    }

    return ttsModels;
  }

  Future<List<String>> getRecommendedSTTModels() async {
    final models = await getModels();
    final sttModels = <String>[];

    for (final model in models) {
      final canDoSTT = model['can_do_voice_conversion'] as bool?;
      if (canDoSTT == true) {
        final modelId = model['model_id'] as String?;
        if (modelId != null) sttModels.add(modelId);
      }
    }

    return sttModels;
  }

  Future<Map<String, bool>> getModelCapabilities(String modelId) async {
    final modelInfo = await getModelInfo(modelId);
    if (modelInfo == null) {
      return {
        'tts': false,
        'stt': false,
        'voice_conversion': false,
        'voice_cloning': false,
      };
    }

    return {
      'tts': modelInfo['can_do_text_to_speech'] as bool? ?? false,
      'stt': modelInfo['can_do_voice_conversion'] as bool? ?? false,
      'voice_conversion':
          modelInfo['can_do_voice_conversion'] as bool? ?? false,
      'voice_cloning': modelInfo['can_be_finetuned'] as bool? ?? false,
    };
  }

  Future<List<String>> getModelLanguages(String modelId) async {
    final modelInfo = await getModelInfo(modelId);
    if (modelInfo == null) return [];

    final languages = modelInfo['languages'] as List<dynamic>?;
    return languages?.cast<String>() ?? [];
  }

  Future<String?> getModelDescription(String modelId) async {
    final modelInfo = await getModelInfo(modelId);
    return modelInfo?['description'] as String?;
  }

  Future<bool> isModelAvailable(String modelId) async {
    try {
      final userInfo = await getUserInfo();
      final subscription = userInfo['subscription'] as Map<String, dynamic>?;
      if (subscription == null) return false;

      final tier = subscription['tier'] as String?;
      final modelInfo = await getModelInfo(modelId);
      if (modelInfo == null) return false;

      return tier != null;
    } catch (_) {
      return false;
    }
  }
}
