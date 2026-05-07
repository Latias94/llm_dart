part of 'openai_completion_support.dart';

final class _OpenAICompletionBatchSupport {
  const _OpenAICompletionBatchSupport();

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
}
