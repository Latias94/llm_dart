final class OpenAILogProbs {
  static const int responsesMaxTopLogProbs = 20;

  final int? topLogProbs;

  const OpenAILogProbs.enabled() : topLogProbs = null;

  const OpenAILogProbs.top(this.topLogProbs)
      : assert(topLogProbs != null ? topLogProbs > 0 : false),
        assert(
          topLogProbs != null ? topLogProbs <= responsesMaxTopLogProbs : false,
        );
}
