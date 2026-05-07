import '../../../../providers/google/config.dart';

/// Builds Google embedding API request payloads.
final class GoogleEmbeddingsRequestBuilder {
  final GoogleConfig config;

  const GoogleEmbeddingsRequestBuilder(this.config);

  Map<String, dynamic> buildSingleEmbeddingRequest(String text) {
    final body = <String, dynamic>{
      'content': _buildContent(text),
    };
    _applyOptionalParameters(body);
    return body;
  }

  Map<String, dynamic> buildBatchEmbeddingRequest(List<String> input) {
    final requests = input.map((text) {
      final request = <String, dynamic>{
        'model': 'models/${config.model}',
        'content': _buildContent(text),
      };
      _applyOptionalParameters(request);
      return request;
    }).toList();

    return {'requests': requests};
  }

  Map<String, dynamic> _buildContent(String text) {
    return {
      'parts': [
        {'text': text}
      ],
    };
  }

  void _applyOptionalParameters(Map<String, dynamic> body) {
    if (config.embeddingTaskType != null) {
      body['taskType'] = config.embeddingTaskType;
    }

    if (config.embeddingTitle != null) {
      body['title'] = config.embeddingTitle;
    }

    if (config.embeddingDimensions != null) {
      body['outputDimensionality'] = config.embeddingDimensions;
    }
  }
}
