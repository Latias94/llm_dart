import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaCompletion implements CompletionCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaCompletion(this.client, this.config);

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    final body = <String, dynamic>{
      'model': config.model,
      'prompt': request.prompt,
      if (config.temperature != null) 'temperature': config.temperature,
      if (config.maxTokens != null) 'max_tokens': config.maxTokens,
    };

    final json = await client.postJson('/v1/completions', body);
    final text = (json['choices'] as List?)?.first['text'] as String?;
    return CompletionResponse(text: text ?? '');
  }
}
