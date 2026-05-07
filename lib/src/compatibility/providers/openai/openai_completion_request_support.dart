part of 'openai_completion_support.dart';

final class _OpenAICompletionRequestSupport {
  const _OpenAICompletionRequestSupport();

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
}
