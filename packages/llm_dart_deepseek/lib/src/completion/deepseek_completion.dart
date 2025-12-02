import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/deepseek_client.dart';
import '../config/deepseek_config.dart';

/// DeepSeek text completion / FIM capability implementation.
///
/// This module provides a lightweight [CompletionCapability] for the
/// DeepSeek API, using the OpenAI-compatible completions endpoint.
///
/// It is suitable for:
/// - Plain text completions
/// - Code/FIM-style completions via [completeFim]
class DeepSeekCompletion implements CompletionCapability {
  final DeepSeekClient client;
  final DeepSeekConfig config;

  DeepSeekCompletion(this.client, this.config);

  /// Endpoint for DeepSeek completions (OpenAI-compatible).
  String get completionsEndpoint => 'completions';

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    final body = <String, dynamic>{
      'model': config.model,
      'prompt': request.prompt,
      if (request.maxTokens != null)
        'max_tokens': request.maxTokens
      else if (config.maxTokens != null)
        'max_tokens': config.maxTokens,
      if (request.temperature != null)
        'temperature': request.temperature
      else if (config.temperature != null)
        'temperature': config.temperature,
      if (request.topP != null)
        'top_p': request.topP
      else if (config.topP != null)
        'top_p': config.topP,
      if (request.topK != null)
        'top_k': request.topK
      else if (config.topK != null)
        'top_k': config.topK,
      if (request.stop != null && request.stop!.isNotEmpty)
        'stop': request.stop,
    };

    final json = await client.postJson(completionsEndpoint, body);

    // DeepSeek completions follow the OpenAI completions shape:
    // choices: [{ text: "...", ... }]
    final choices = json['choices'] as List?;
    String text = '';

    if (choices != null && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final textField = first['text'] as String?;
        if (textField != null) {
          text = textField;
        } else {
          // Fallback to chat-style content if present.
          final message = first['message'] as Map<String, dynamic>?;
          text = message?['content'] as String? ?? '';
        }
      }
    }

    UsageInfo? usage;
    final rawUsage = json['usage'];
    if (rawUsage is Map<String, dynamic>) {
      usage = UsageInfo.fromJson(rawUsage);
    } else if (rawUsage is Map) {
      usage = UsageInfo.fromJson(Map<String, dynamic>.from(rawUsage));
    }

    return CompletionResponse(text: text, usage: usage);
  }

  /// FIM (Fill-In-the-Middle) / code completion helper.
  ///
  /// This method maps the prefix/suffix-style arguments to the
  /// DeepSeek completions API. It uses the same endpoint as [complete]
  /// but sends both `prompt` and `suffix` to the model.
  Future<CompletionResponse> completeFim({
    required String prefix,
    required String suffix,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? topK,
    List<String>? stop,
  }) async {
    final body = <String, dynamic>{
      'model': config.model,
      'prompt': prefix,
      'suffix': suffix,
      if (maxTokens != null)
        'max_tokens': maxTokens
      else if (config.maxTokens != null)
        'max_tokens': config.maxTokens,
      if (temperature != null)
        'temperature': temperature
      else if (config.temperature != null)
        'temperature': config.temperature,
      if (topP != null)
        'top_p': topP
      else if (config.topP != null)
        'top_p': config.topP,
      if (topK != null)
        'top_k': topK
      else if (config.topK != null)
        'top_k': config.topK,
      if (stop != null && stop.isNotEmpty) 'stop': stop,
    };

    final json = await client.postJson(completionsEndpoint, body);

    final choices = json['choices'] as List?;
    String text = '';

    if (choices != null && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final textField = first['text'] as String?;
        if (textField != null) {
          text = textField;
        } else {
          final message = first['message'] as Map<String, dynamic>?;
          text = message?['content'] as String? ?? '';
        }
      }
    }

    UsageInfo? usage;
    final rawUsage = json['usage'];
    if (rawUsage is Map<String, dynamic>) {
      usage = UsageInfo.fromJson(rawUsage);
    } else if (rawUsage is Map) {
      usage = UsageInfo.fromJson(Map<String, dynamic>.from(rawUsage));
    }

    return CompletionResponse(text: text, usage: usage);
  }
}
