part of 'openai_completion_support.dart';

final class _OpenAICompletionPresetSupport {
  const _OpenAICompletionPresetSupport();

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
}
