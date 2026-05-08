import 'package:llm_dart_transport/dio.dart';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../providers/ollama/client.dart';
import '../../../../providers/ollama/config.dart';
import '../../http/dio_error_handler.dart';

/// Compatibility-oriented Ollama completion implementation for `/api/generate`.
class OllamaCompletion implements CompletionCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaCompletion(this.client, this.config);

  String get completionEndpoint => '/api/generate';

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    if (config.baseUrl.isEmpty) {
      throw const InvalidRequestError('Missing Ollama base URL');
    }

    try {
      final requestBody = _buildRequestBody(request);
      final responseData =
          await client.postJson(completionEndpoint, requestBody);
      return _parseResponse(responseData);
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  Map<String, dynamic> _buildRequestBody(CompletionRequest request) {
    final body = <String, dynamic>{
      'model': config.model,
      'prompt': request.prompt,
      'raw': true,
      'stream': false,
    };

    final options = <String, dynamic>{};
    if (config.temperature != null) options['temperature'] = config.temperature;
    if (config.topP != null) options['top_p'] = config.topP;
    if (config.topK != null) options['top_k'] = config.topK;
    if (config.maxTokens != null) options['num_predict'] = config.maxTokens;
    if (config.numCtx != null) options['num_ctx'] = config.numCtx;
    if (config.numGpu != null) options['num_gpu'] = config.numGpu;
    if (config.numThread != null) options['num_thread'] = config.numThread;
    if (config.numa != null) options['numa'] = config.numa;
    if (config.numBatch != null) options['num_batch'] = config.numBatch;

    if (options.isNotEmpty) {
      body['options'] = options;
    }

    body['keep_alive'] = config.keepAlive ?? '5m';

    if (config.reasoning != null) {
      body['think'] = config.reasoning;
    }

    return body;
  }

  CompletionResponse _parseResponse(Map<String, dynamic> responseData) {
    final text = responseData['response'] as String? ??
        responseData['content'] as String?;

    if (text == null || text.isEmpty) {
      throw const ProviderError('No answer returned by Ollama');
    }

    final thinking = responseData['thinking'] as String?;

    return CompletionResponse(text: text, thinking: thinking);
  }
}
