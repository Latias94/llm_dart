part of 'models.dart';

final class _OpenAIModelsFetchSupport {
  final OpenAIClient client;

  const _OpenAIModelsFetchSupport(this.client);

  Future<List<AIModel>> models({
    TransportCancellation? cancelToken,
  }) async {
    final responseData = await client.get('models', cancelToken: cancelToken);
    final modelsData = responseData['data'] as List?;
    if (modelsData == null) {
      return [];
    }

    final models = modelsData
        .map((modelData) {
          if (modelData is! Map<String, dynamic>) return null;

          try {
            return AIModel(
              id: modelData['id'] as String,
              description: modelData['description'] as String?,
              object: modelData['object'] as String? ?? 'model',
              ownedBy: modelData['owned_by'] as String?,
            );
          } catch (e) {
            client.logger.warning('Failed to parse model: $e');
            return null;
          }
        })
        .where((model) => model != null)
        .cast<AIModel>()
        .toList();

    client.logger.fine('Retrieved ${models.length} models from OpenAI');
    return models;
  }

  Future<AIModel?> getModel(String modelId) async {
    try {
      final responseData = await client.get('models/$modelId');

      return AIModel(
        id: responseData['id'] as String,
        description: responseData['description'] as String?,
        object: responseData['object'] as String? ?? 'model',
        ownedBy: responseData['owned_by'] as String?,
      );
    } catch (e) {
      if (e is ResponseFormatError && e.message.contains('404')) {
        return null;
      }
      rethrow;
    }
  }
}
