import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Anthropic Models capability implementation
///
/// This module handles model listing functionality for Anthropic providers.
/// Reference: https://docs.anthropic.com/en/api/models-list
class AnthropicModels {
  final AnthropicClient client;
  final AnthropicConfig config;

  AnthropicModels(this.client, this.config);

  String get modelsEndpoint => 'models';

  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    return listModels(cancelToken: cancelToken);
  }

  /// List available models from Anthropic API
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/models-list
  ///
  /// Supports pagination with [beforeId], [afterId], and [limit] parameters.
  /// Returns a list of available models with their metadata.
  Future<List<AIModel>> listModels({
    String? beforeId,
    String? afterId,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (beforeId != null) queryParams['before_id'] = beforeId;
      if (afterId != null) queryParams['after_id'] = afterId;
      if (limit != 20) queryParams['limit'] = limit;

      final endpoint = queryParams.isEmpty
          ? modelsEndpoint
          : '$modelsEndpoint?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final responseData = await client.getJson(
        endpoint,
        cancelToken: cancelToken,
      );
      final data = responseData['data'] as List?;

      if (data == null) return [];

      return data
          .map((modelData) =>
              AIModel.fromJson(modelData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      client.logger.warning('Failed to list models: $e');
      return [];
    }
  }

  /// Get information about a specific model
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/models
  ///
  /// Returns detailed information about a specific model including its
  /// capabilities, creation date, and display name.
  Future<AIModel?> getModel(String modelId) async {
    try {
      final responseData = await client.getJson('$modelsEndpoint/$modelId');
      return AIModel.fromJson(responseData);
    } catch (e) {
      client.logger.warning('Failed to get model $modelId: $e');
      return null;
    }
  }
}
