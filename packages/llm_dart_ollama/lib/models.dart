import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'client.dart';
import 'config.dart';

/// Ollama Models capability implementation
///
/// This module handles model listing functionality for Ollama providers.
/// Ollama supports listing available models through the /api/tags endpoint.
class OllamaModels {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaModels(this.client, this.config);

  String get modelsEndpoint => '/api/tags';

  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    if (config.baseUrl.isEmpty) {
      throw const InvalidRequestError('Missing Ollama base URL');
    }

    try {
      final responseData = await client.getJson(
        modelsEndpoint,
        cancelToken: cancelToken,
      );
      return _parseResponse(responseData);
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  /// Parse models response
  List<AIModel> _parseResponse(Map<String, dynamic> responseData) {
    final modelsData = responseData['models'] as List?;
    if (modelsData == null) {
      return [];
    }

    // Convert Ollama model format to AIModel
    final models = modelsData
        .map((modelData) {
          if (modelData is! Map<String, dynamic>) return null;

          try {
            return AIModel(
              id: modelData['name'] as String,
              description: modelData['details']?['family'] as String?,
              object: 'model',
              ownedBy: 'ollama',
            );
          } catch (e) {
            client.logger.warning('Failed to parse model: $e');
            return null;
          }
        })
        .where((model) => model != null)
        .cast<AIModel>()
        .toList();

    client.logger.fine('Retrieved ${models.length} models from Ollama');
    return models;
  }
}
