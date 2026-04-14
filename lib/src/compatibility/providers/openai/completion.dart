import '../../../../core/capability.dart';
import '../../../../providers/openai/config.dart';
import 'client.dart';
import 'openai_completion_support.dart';

export 'openai_completion_support.dart' show CompletionUseCase;

/// OpenAI Text Completion capability implementation.
///
/// This module keeps the compatibility endpoint orchestration for text
/// completion while delegating deterministic helper logic to provider-local
/// support.
class OpenAICompletion implements CompletionCapability {
  final OpenAIClient client;
  final OpenAIConfig config;
  final OpenAICompletionSupport _support = const OpenAICompletionSupport();

  OpenAICompletion(this.client, this.config);

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    final requestBody = _support.buildRequestBody(
      client: client,
      config: config,
      request: request,
      stream: false,
    );
    final responseData = await client.postJson('chat/completions', requestBody);
    return _support.parseResponse(responseData);
  }

  /// Complete text with streaming support.
  Stream<String> completeStream(CompletionRequest request) async* {
    final requestBody = _support.buildRequestBody(
      client: client,
      config: config,
      request: request,
      stream: true,
    );

    final stream = client.postStreamRaw('chat/completions', requestBody);
    await for (final chunk in stream) {
      for (final delta in _support.parseStreamDeltas(client, chunk)) {
        yield delta;
      }
    }
  }

  /// Generate multiple completions for the same prompt.
  Future<List<CompletionResponse>> generateMultiple(
    CompletionRequest request,
    int count,
  ) {
    return _support.generateMultiple(
      request,
      count,
      complete,
    );
  }

  /// Complete with custom parameters.
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
    final request = _support.buildRequestFromParams(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      stop: stop,
    );

    return complete(request);
  }

  /// Complete with best practices for different use cases.
  Future<CompletionResponse> completeForUseCase(
    String prompt,
    CompletionUseCase useCase,
  ) {
    final request = _support.buildUseCaseRequest(prompt, useCase);
    return complete(request);
  }

  /// Complete with retry logic for better reliability.
  Future<CompletionResponse> completeWithRetry(
    CompletionRequest request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) {
    return _support.completeWithRetry(
      () => complete(request),
      maxRetries: maxRetries,
      delay: delay,
    );
  }

  /// Batch complete multiple prompts.
  Future<List<CompletionResponse>> batchComplete(
    List<String> prompts, {
    String? model,
    int? maxTokens,
    double? temperature,
    int? concurrency = 5,
  }) {
    return _support.batchComplete(
      prompts: prompts,
      maxTokens: maxTokens,
      temperature: temperature,
      concurrency: concurrency,
      complete: complete,
    );
  }

  /// Estimate token count for a prompt.
  int estimateTokenCount(String text) {
    return _support.estimateTokenCount(text);
  }

  /// Check if prompt is within token limits.
  bool isPromptWithinLimits(String prompt, {int? maxTokens}) {
    return _support.isPromptWithinLimits(prompt, maxTokens: maxTokens);
  }

  /// Truncate prompt to fit within token limits.
  String truncatePrompt(String prompt, {int? maxTokens}) {
    return _support.truncatePrompt(prompt, maxTokens: maxTokens);
  }
}
