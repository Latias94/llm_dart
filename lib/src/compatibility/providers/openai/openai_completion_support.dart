import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/openai/config.dart';
import 'client.dart';

/// Provider-local support for the OpenAI completion compatibility shell.
///
/// This keeps deterministic request shaping, response parsing, use-case
/// presets, retry helpers, and token heuristics out of the API shell.
final class OpenAICompletionSupport {
  const OpenAICompletionSupport();

  Map<String, dynamic> buildRequestBody({
    required OpenAIClient client,
    required OpenAIConfig config,
    required CompletionRequest request,
    required bool stream,
  }) {
    final messages = [ChatMessage.user(request.prompt)];

    return <String, dynamic>{
      'model': config.model,
      'messages': client.buildApiMessages(messages),
      'stream': stream,
      if (request.maxTokens != null) 'max_tokens': request.maxTokens,
      if (request.temperature != null) 'temperature': request.temperature,
      if (request.topP != null) 'top_p': request.topP,
      if (request.stop != null) 'stop': request.stop,
    };
  }

  CompletionResponse parseResponse(Map<String, dynamic> responseData) {
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

  List<String> parseStreamDeltas(
    OpenAIClient client,
    String chunk,
  ) {
    final deltas = <String>[];
    final jsonList = client.parseSSEChunk(chunk);
    if (jsonList.isEmpty) {
      return deltas;
    }

    for (final json in jsonList) {
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        continue;
      }

      final choice = choices.first as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>?;
      if (delta == null) {
        continue;
      }

      final content = delta['content'] as String?;
      if (content != null && content.isNotEmpty) {
        deltas.add(content);
      }
    }

    return deltas;
  }

  Future<List<CompletionResponse>> generateMultiple(
    CompletionRequest request,
    int count,
    Future<CompletionResponse> Function(CompletionRequest request) complete,
  ) async {
    final results = <CompletionResponse>[];
    for (var index = 0; index < count; index++) {
      final response = await complete(request);
      results.add(response);
    }

    return results;
  }

  CompletionRequest buildRequestFromParams({
    required String prompt,
    int? maxTokens,
    double? temperature,
    double? topP,
    List<String>? stop,
  }) {
    return CompletionRequest(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      stop: stop,
    );
  }

  CompletionRequest buildUseCaseRequest(
    String prompt,
    CompletionUseCase useCase,
  ) {
    return switch (useCase) {
      CompletionUseCase.creative => CompletionRequest(
          prompt: prompt,
          temperature: 0.9,
          topP: 1.0,
          maxTokens: 1000,
        ),
      CompletionUseCase.factual => CompletionRequest(
          prompt: prompt,
          temperature: 0.1,
          topP: 0.1,
          maxTokens: 500,
        ),
      CompletionUseCase.conversational => CompletionRequest(
          prompt: prompt,
          temperature: 0.7,
          topP: 0.9,
          maxTokens: 800,
        ),
      CompletionUseCase.code => CompletionRequest(
          prompt: prompt,
          temperature: 0.2,
          topP: 0.1,
          maxTokens: 1500,
          stop: ['\n\n', '```'],
        ),
      CompletionUseCase.summarization => CompletionRequest(
          prompt: prompt,
          temperature: 0.3,
          topP: 0.8,
          maxTokens: 300,
        ),
    };
  }

  Future<CompletionResponse> completeWithRetry(
    Future<CompletionResponse> Function() execute, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    Exception? lastException;

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await execute();
      } catch (error) {
        lastException =
            error is Exception ? error : Exception(error.toString());

        if (attempt < maxRetries - 1) {
          await Future.delayed(delay * (attempt + 1));
        }
      }
    }

    throw lastException!;
  }

  Future<List<CompletionResponse>> batchComplete({
    required List<String> prompts,
    required int? maxTokens,
    required double? temperature,
    required int? concurrency,
    required Future<CompletionResponse> Function(CompletionRequest request)
        complete,
  }) async {
    final results = <CompletionResponse>[];
    final batchSize = concurrency ?? 5;

    for (var index = 0; index < prompts.length; index += batchSize) {
      final batch = prompts.skip(index).take(batchSize);
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

/// Use cases for completion optimization.
enum CompletionUseCase {
  creative,
  factual,
  conversational,
  code,
  summarization,
}
