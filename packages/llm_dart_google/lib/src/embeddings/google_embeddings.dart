import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/google_client.dart';
import '../config/google_config.dart';

class GoogleEmbeddings implements EmbeddingCapability {
  final GoogleClient client;
  final GoogleConfig config;

  GoogleEmbeddings(this.client, this.config);

  String get embeddingEndpoint => 'models/${config.model}:embedContent';
  String get batchEmbeddingEndpoint =>
      'models/${config.model}:batchEmbedContents';

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing Google API key');
    }

    try {
      if (input.length == 1) {
        final requestBody = _buildSingleEmbeddingRequest(input.first);
        final responseData = await client.postJson(
          embeddingEndpoint,
          requestBody,
          cancelToken: cancelToken,
        );
        return [_parseSingleEmbeddingResponse(responseData)];
      } else {
        final requestBody = _buildBatchEmbeddingRequest(input);
        final responseData = await client.postJson(
          batchEmbeddingEndpoint,
          requestBody,
          cancelToken: cancelToken,
        );
        return _parseBatchEmbeddingResponse(responseData);
      }
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Google');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Map<String, dynamic> _buildSingleEmbeddingRequest(String text) {
    final body = <String, dynamic>{
      'content': {
        'parts': [
          {'text': text}
        ]
      },
    };

    if (config.embeddingTaskType != null) {
      body['taskType'] = config.embeddingTaskType;
    }

    if (config.embeddingTitle != null) {
      body['title'] = config.embeddingTitle;
    }

    if (config.embeddingDimensions != null) {
      body['outputDimensionality'] = config.embeddingDimensions;
    }

    return body;
  }

  Map<String, dynamic> _buildBatchEmbeddingRequest(List<String> input) {
    final requests = input.map((text) {
      final request = <String, dynamic>{
        'model': 'models/${config.model}',
        'content': {
          'parts': [
            {'text': text}
          ]
        },
      };

      if (config.embeddingTaskType != null) {
        request['taskType'] = config.embeddingTaskType;
      }

      if (config.embeddingTitle != null) {
        request['title'] = config.embeddingTitle;
      }

      if (config.embeddingDimensions != null) {
        request['outputDimensionality'] = config.embeddingDimensions;
      }

      return request;
    }).toList();

    return {'requests': requests};
  }

  List<double> _parseSingleEmbeddingResponse(
      Map<String, dynamic> responseData) {
    final embedding = responseData['embedding'] as Map<String, dynamic>?;
    if (embedding == null) {
      throw ResponseFormatError(
        'Invalid embedding response format: missing embedding field',
        responseData.toString(),
      );
    }

    final values = embedding['values'] as List?;
    if (values == null) {
      throw ResponseFormatError(
        'Invalid embedding format: missing values field',
        embedding.toString(),
      );
    }

    try {
      return values.cast<double>();
    } catch (e) {
      throw ResponseFormatError(
        'Failed to parse embedding values: $e',
        values.toString(),
      );
    }
  }

  List<List<double>> _parseBatchEmbeddingResponse(
      Map<String, dynamic> responseData) {
    final embeddings = responseData['embeddings'] as List?;
    if (embeddings == null) {
      throw ResponseFormatError(
        'Invalid batch embedding response format: missing embeddings field',
        responseData.toString(),
      );
    }

    try {
      return embeddings.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ResponseFormatError(
            'Invalid embedding item format: expected Map<String, dynamic>',
            item.toString(),
          );
        }

        final embedding = item['embedding'] as Map<String, dynamic>?;
        if (embedding == null) {
          throw ResponseFormatError(
            'Invalid embedding item format: missing embedding field',
            item.toString(),
          );
        }

        final values = embedding['values'] as List?;
        if (values == null) {
          throw ResponseFormatError(
            'Invalid embedding format: missing values field',
            embedding.toString(),
          );
        }

        return values.cast<double>();
      }).toList();
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse batch embedding response: $e',
        responseData.toString(),
      );
    }
  }

  Future<int> getEmbeddingDimensions() async {
    final requestBody = _buildSingleEmbeddingRequest('test');
    final responseData = await client.postJson(embeddingEndpoint, requestBody);
    final embedding = _parseSingleEmbeddingResponse(responseData);
    return embedding.length;
  }
}
