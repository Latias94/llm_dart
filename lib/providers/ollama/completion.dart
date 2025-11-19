import 'package:dio/dio.dart';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import 'client.dart';
import 'config.dart';

/// Ollama Completion capability implementation
///
/// This module handles completion functionality for Ollama providers.
/// Ollama supports text completion through the /api/generate endpoint.
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

  /// Build request body for Ollama completion API
  Map<String, dynamic> _buildRequestBody(CompletionRequest request) {
    final body = <String, dynamic>{
      'model': config.model,
      'prompt': request.prompt,
      'raw': true,
      'stream': false,
    };

    // Add options - Ollama supports temperature and other parameters
    final options = <String, dynamic>{};
    if (config.temperature != null) options['temperature'] = config.temperature;
    if (config.topP != null) options['top_p'] = config.topP;
    if (config.topK != null) options['top_k'] = config.topK;
    if (config.maxTokens != null) options['num_predict'] = config.maxTokens;

    // Ollama-specific options
    if (config.numCtx != null) options['num_ctx'] = config.numCtx;
    if (config.numGpu != null) options['num_gpu'] = config.numGpu;
    if (config.numThread != null) options['num_thread'] = config.numThread;
    if (config.numa != null) options['numa'] = config.numa;
    if (config.numBatch != null) options['num_batch'] = config.numBatch;

    if (options.isNotEmpty) {
      body['options'] = options;
    }

    // Add keep_alive parameter for model memory management
    body['keep_alive'] = config.keepAlive ?? '5m'; // Default 5 minutes

    // Add thinking parameter, if not passed, it will depend on the model's default behavior
    if (config.reasoning != null) {
      body['think'] = config.reasoning;
    }

    return body;
  }

  /// Parse completion response
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
