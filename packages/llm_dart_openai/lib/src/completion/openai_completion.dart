// OpenAI text completion capability implemented on top of the
// ChatMessage-based chat completions API for compatibility.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/openai_client.dart';
import '../config/openai_config.dart';

/// OpenAI Text Completion capability implementation
///
/// This module handles text completion functionality for OpenAI providers.
/// Note: OpenAI has deprecated the completions endpoint in favor of chat completions.
class OpenAICompletion implements CompletionCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAICompletion(this.client, this.config);

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    final messages = [ChatMessage.user(request.prompt)];
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();

    final requestBody = <String, dynamic>{
      'model': config.model,
      'messages': client.buildApiMessagesFromPrompt(promptMessages),
      'stream': false,
      if (request.maxTokens != null) 'max_tokens': request.maxTokens,
      if (request.temperature != null) 'temperature': request.temperature,
      if (request.topP != null) 'top_p': request.topP,
      if (request.stop != null) 'stop': request.stop,
    };

    final responseData = await client.postJson('chat/completions', requestBody);

    final choices = responseData['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return const CompletionResponse(text: '');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final text = message?['content'] as String? ?? '';

    UsageInfo? usage;
    final usageData = responseData['usage'] as Map<String, dynamic>?;
    if (usageData != null) {
      usage = UsageInfo.fromJson(usageData);
    }

    return CompletionResponse(text: text, usage: usage);
  }

  Stream<String> completeStream(CompletionRequest request) async* {
    final messages = [ChatMessage.user(request.prompt)];
    final promptMessages =
        messages.map((message) => message.toPromptMessage()).toList();

    final requestBody = <String, dynamic>{
      'model': config.model,
      'messages': client.buildApiMessagesFromPrompt(promptMessages),
      'stream': true,
      if (request.maxTokens != null) 'max_tokens': request.maxTokens,
      if (request.temperature != null) 'temperature': request.temperature,
      if (request.topP != null) 'top_p': request.topP,
      if (request.stop != null) 'stop': request.stop,
    };

    final stream = client.postStreamRaw('chat/completions', requestBody);

    await for (final chunk in stream) {
      final jsonList = client.parseSSEChunk(chunk);
      if (jsonList.isEmpty) continue;

      for (final json in jsonList) {
        final choices = json['choices'] as List?;
        if (choices == null || choices.isEmpty) continue;

        final choice = choices.first as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        if (delta == null) continue;

        final content = delta['content'] as String?;
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    }
  }

  Future<List<CompletionResponse>> generateMultiple(
    CompletionRequest request,
    int count,
  ) async {
    final results = <CompletionResponse>[];

    for (int i = 0; i < count; i++) {
      final response = await complete(request);
      results.add(response);
    }

    return results;
  }

  Future<CompletionResponse> completeWithParams({
    required String prompt,
    String? model,
    int? maxTokens,
    double? temperature,
    double? topP,
    List<String>? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    String? suffix,
    bool echo = false,
  }) async {
    final request = CompletionRequest(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      stop: stop,
    );

    return complete(request);
  }

  Future<CompletionResponse> completeForUseCase(
    String prompt,
    CompletionUseCase useCase,
  ) async {
    CompletionRequest request;

    switch (useCase) {
      case CompletionUseCase.creative:
        request = CompletionRequest(
          prompt: prompt,
          temperature: 0.9,
          topP: 1.0,
          maxTokens: 1000,
        );
        break;
      case CompletionUseCase.factual:
        request = CompletionRequest(
          prompt: prompt,
          temperature: 0.1,
          topP: 0.1,
          maxTokens: 500,
        );
        break;
      case CompletionUseCase.conversational:
        request = CompletionRequest(
          prompt: prompt,
          temperature: 0.7,
          topP: 0.9,
          maxTokens: 800,
        );
        break;
      case CompletionUseCase.code:
        request = CompletionRequest(
          prompt: prompt,
          temperature: 0.2,
          topP: 0.1,
          maxTokens: 1500,
          stop: ['\n\n', '```'],
        );
        break;
      case CompletionUseCase.summarization:
        request = CompletionRequest(
          prompt: prompt,
          temperature: 0.3,
          topP: 0.8,
          maxTokens: 300,
        );
        break;
    }

    return complete(request);
  }

  Future<CompletionResponse> completeWithRetry(
    CompletionRequest request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await complete(request);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt < maxRetries - 1) {
          await Future.delayed(delay * (attempt + 1));
        }
      }
    }

    throw lastException!;
  }

  Future<List<CompletionResponse>> batchComplete(
    List<String> prompts, {
    String? model,
    int? maxTokens,
    double? temperature,
    int? concurrency = 5,
  }) async {
    final results = <CompletionResponse>[];

    final batchSize = concurrency ?? 5;
    for (int i = 0; i < prompts.length; i += batchSize) {
      final batch = prompts.skip(i).take(batchSize);
      final futures = batch.map(
        (prompt) => complete(
          CompletionRequest(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: temperature,
          ),
        ),
      );

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);
    }

    return results;
  }

  int estimateTokenCount(String text) {
    return (text.length / 4).ceil();
  }

  bool isPromptWithinLimits(String prompt, {int? maxTokens}) {
    final estimatedTokens = estimateTokenCount(prompt);
    final limit = maxTokens ?? 4096;
    return estimatedTokens <= limit;
  }

  String truncatePrompt(String prompt, {int? maxTokens}) {
    final limit = maxTokens ?? 4096;
    final estimatedTokens = estimateTokenCount(prompt);

    if (estimatedTokens <= limit) {
      return prompt;
    }

    final targetLength = (limit * 4 * 0.9).round();
    return prompt.substring(0, targetLength.clamp(0, prompt.length));
  }
}

/// Use cases for completion optimization
enum CompletionUseCase {
  creative,
  factual,
  conversational,
  code,
  summarization,
}
