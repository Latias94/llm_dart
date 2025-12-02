import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/ollama_client.dart';
import '../config/ollama_config.dart';

class OllamaCompletion implements CompletionCapability {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaCompletion(this.client, this.config);

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    // Native Ollama `/api/generate` completion endpoint.
    final options = <String, dynamic>{};

    // Prefer request-level parameters over config-level defaults.
    final temperature = request.temperature ?? config.temperature;
    if (temperature != null) {
      options['temperature'] = temperature;
    }

    final maxTokens = request.maxTokens ?? config.maxTokens;
    if (maxTokens != null) {
      options['num_predict'] = maxTokens;
    }

    final topP = request.topP ?? config.topP;
    if (topP != null) {
      options['top_p'] = topP;
    }

    final topK = request.topK ?? config.topK;
    if (topK != null) {
      options['top_k'] = topK;
    }

    if (config.numCtx != null) {
      options['num_ctx'] = config.numCtx;
    }
    if (config.numGpu != null) {
      options['num_gpu'] = config.numGpu;
    }
    if (config.numThread != null) {
      options['num_thread'] = config.numThread;
    }
    if (config.numBatch != null) {
      options['num_batch'] = config.numBatch;
    }
    if (config.numa != null) {
      options['numa'] = config.numa;
    }
    if (config.keepAlive != null) {
      // keep_alive is a top-level parameter in the Ollama
      // generate API, not part of options.
    }
    if (config.raw != null) {
      // raw is a top-level parameter for generate.
    }

    final body = <String, dynamic>{
      'model': config.model,
      'prompt': request.prompt,
      // Request a single consolidated response.
      'stream': false,
      if (options.isNotEmpty) 'options': options,
    };

    // Top-level advanced parameters aligned with Ollama docs.
    if (config.keepAlive != null) {
      body['keep_alive'] = config.keepAlive;
    }
    if (config.raw != null) {
      body['raw'] = config.raw;
    }

    // Thinking / reasoning flag for thinking models.
    if (config.reasoning == true) {
      body['think'] = true;
    }

    // Structured outputs / JSON mode via `format` parameter.
    if (config.jsonSchema != null) {
      final schema = config.jsonSchema!;
      if (schema.schema != null) {
        body['format'] = schema.schema;
      } else {
        body['format'] = 'json';
      }
    }

    // System prompt support for generate endpoint.
    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      body['system'] = config.systemPrompt;
    }

    final json = await client.postJson('/api/generate', body);

    final text = json['response'] as String? ?? '';

    // Thinking content for reasoning models.
    String? thinking;
    final message = json['message'] as Map<String, dynamic>?;
    if (message != null) {
      final messageThinking = message['thinking'] as String?;
      if (messageThinking != null && messageThinking.isNotEmpty) {
        thinking = messageThinking;
      }
    }
    final directThinking = json['thinking'] as String?;
    if (directThinking != null && directThinking.isNotEmpty) {
      thinking ??= directThinking;
    }

    // Map usage metrics when available.
    UsageInfo? usage;
    final promptTokens = json['prompt_eval_count'] as int?;
    final completionTokens = json['eval_count'] as int?;
    int? totalTokens = json['total_tokens'] as int?;

    if (totalTokens == null &&
        promptTokens != null &&
        completionTokens != null) {
      totalTokens = promptTokens + completionTokens;
    }

    if (promptTokens != null ||
        completionTokens != null ||
        totalTokens != null) {
      usage = UsageInfo(
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        reasoningTokens: null,
      );
    }

    return CompletionResponse(
      text: text,
      usage: usage,
      thinking: thinking,
    );
  }
}
