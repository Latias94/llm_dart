part of 'openai_builder.dart';

mixin _OpenAIBuilderPresets {
  OpenAIBuilder frequencyPenalty(double penalty);

  OpenAIBuilder presencePenalty(double penalty);

  OpenAIBuilder parallelToolCalls(bool enabled);

  OpenAIBuilder seed(int seedValue);

  OpenAIBuilder logprobs(bool enabled);

  OpenAIBuilder topLogprobs(int count);

  /// Configure for creative writing with reduced repetition.
  OpenAIBuilder forCreativeWriting() {
    return frequencyPenalty(0.5).presencePenalty(0.6).parallelToolCalls(false);
  }

  /// Configure for factual and consistent responses.
  OpenAIBuilder forFactualResponses({int? seed}) {
    final builder =
        frequencyPenalty(0.0).presencePenalty(0.0).parallelToolCalls(true);

    if (seed != null) {
      builder.seed(seed);
    }

    return builder;
  }

  /// Configure for code generation with deterministic output.
  OpenAIBuilder forCodeGeneration({int? seed}) {
    final builder =
        frequencyPenalty(0.1).presencePenalty(0.1).parallelToolCalls(true);

    if (seed != null) {
      builder.seed(seed);
    }

    return builder;
  }

  /// Configure for conversational AI with balanced creativity.
  OpenAIBuilder forConversation() {
    return frequencyPenalty(0.3).presencePenalty(0.4).parallelToolCalls(true);
  }

  /// Configure for analysis tasks with log probabilities.
  OpenAIBuilder forAnalysis({int topLogprobsCount = 5}) {
    return frequencyPenalty(0.1)
        .presencePenalty(0.1)
        .logprobs(true)
        .topLogprobs(topLogprobsCount)
        .parallelToolCalls(true);
  }
}
