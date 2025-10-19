import 'package:dio/dio.dart';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import 'client.dart';
import 'config.dart';

/// xAI Embedding capability implementation
///
/// This module handles embedding generation functionality for xAI providers.
/// xAI provides embedding models compatible with OpenAI's embedding API.
class XAIEmbedding implements EmbeddingCapability {
  final XAIClient client;
  final XAIConfig config;

  XAIEmbedding(this.client, this.config);

  String get embeddingEndpoint => 'embeddings';

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing xAI API key');
    }

    final requestBody = _buildEmbeddingRequest(input);
    final responseData = await client.postJson(
      embeddingEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return _parseEmbeddingResponse(responseData);
  }

  /// Build request body for embedding API
  Map<String, dynamic> _buildEmbeddingRequest(List<String> input) {
    final embeddingFormat = config.embeddingEncodingFormat ?? 'float';

    final body = <String, dynamic>{
      'model': config.model,
      'input': input,
      'encoding_format': embeddingFormat,
    };

    if (config.embeddingDimensions != null) {
      body['dimensions'] = config.embeddingDimensions;
    }

    return body;
  }

  /// Parse embedding response from xAI API
  List<List<double>> _parseEmbeddingResponse(
      Map<String, dynamic> responseData) {
    final embeddingResponse = XAIEmbeddingResponse.fromJson(responseData);
    return embeddingResponse.data.map((d) => d.embedding).toList();
  }
}

/// Embedding data from xAI API
class XAIEmbeddingData {
  final List<double> embedding;

  XAIEmbeddingData(this.embedding);

  factory XAIEmbeddingData.fromJson(Map<String, dynamic> json) {
    final embeddingList = json['embedding'] as List;
    return XAIEmbeddingData(
      embeddingList.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

/// Embedding response from xAI API
class XAIEmbeddingResponse {
  final List<XAIEmbeddingData> data;

  XAIEmbeddingResponse(this.data);

  factory XAIEmbeddingResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    return XAIEmbeddingResponse(
      dataList
          .map(
            (item) => XAIEmbeddingData.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
