import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/openai/config.dart';
import 'client.dart';

part 'openai_completion_batch_support.dart';
part 'openai_completion_preset_support.dart';
part 'openai_completion_prompt_support.dart';
part 'openai_completion_request_support.dart';
part 'openai_completion_response_support.dart';

/// Provider-local support for the OpenAI completion compatibility shell.
///
/// This keeps deterministic request shaping, response parsing, use-case
/// presets, retry helpers, and token heuristics out of the API shell.
final class OpenAICompletionSupport {
  static const _requestSupport = _OpenAICompletionRequestSupport();
  static const _responseSupport = _OpenAICompletionResponseSupport();
  static const _batchSupport = _OpenAICompletionBatchSupport();
  static const _promptSupport = _OpenAICompletionPromptSupport();
  static const _presetSupport = _OpenAICompletionPresetSupport();

  const OpenAICompletionSupport();

  Map<String, dynamic> buildRequestBody({
    required OpenAIClient client,
    required OpenAIConfig config,
    required CompletionRequest request,
    required bool stream,
  }) {
    return _requestSupport.buildRequestBody(
      client: client,
      config: config,
      request: request,
      stream: stream,
    );
  }

  CompletionResponse parseResponse(Map<String, dynamic> responseData) {
    return _responseSupport.parseResponse(responseData);
  }

  List<String> parseStreamDeltas(
    OpenAIClient client,
    String chunk,
  ) {
    return _responseSupport.parseStreamDeltas(client, chunk);
  }

  Future<List<CompletionResponse>> generateMultiple(
    CompletionRequest request,
    int count,
    Future<CompletionResponse> Function(CompletionRequest request) complete,
  ) async {
    return _batchSupport.generateMultiple(request, count, complete);
  }

  CompletionRequest buildRequestFromParams({
    required String prompt,
    int? maxTokens,
    double? temperature,
    double? topP,
    List<String>? stop,
  }) {
    return _requestSupport.buildRequestFromParams(
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
    return _presetSupport.buildUseCaseRequest(prompt, useCase);
  }

  Future<CompletionResponse> completeWithRetry(
    Future<CompletionResponse> Function() execute, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    return _batchSupport.completeWithRetry(
      execute,
      maxRetries: maxRetries,
      delay: delay,
    );
  }

  Future<List<CompletionResponse>> batchComplete({
    required List<String> prompts,
    required int? maxTokens,
    required double? temperature,
    required int? concurrency,
    required Future<CompletionResponse> Function(CompletionRequest request)
        complete,
  }) async {
    return _batchSupport.batchComplete(
      prompts: prompts,
      maxTokens: maxTokens,
      temperature: temperature,
      concurrency: concurrency,
      complete: complete,
    );
  }

  int estimateTokenCount(String text) {
    return _promptSupport.estimateTokenCount(text);
  }

  bool isPromptWithinLimits(String prompt, {int? maxTokens}) {
    return _promptSupport.isPromptWithinLimits(
      prompt,
      maxTokens: maxTokens,
    );
  }

  String truncatePrompt(String prompt, {int? maxTokens}) {
    return _promptSupport.truncatePrompt(prompt, maxTokens: maxTokens);
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
