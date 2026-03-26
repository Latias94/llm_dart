final class UsageStats {
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final int? reasoningTokens;

  const UsageStats({
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.reasoningTokens,
  });

  UsageStats operator +(UsageStats other) {
    return UsageStats(
      inputTokens: (inputTokens ?? 0) + (other.inputTokens ?? 0),
      outputTokens: (outputTokens ?? 0) + (other.outputTokens ?? 0),
      totalTokens: (totalTokens ?? 0) + (other.totalTokens ?? 0),
      reasoningTokens: (reasoningTokens ?? 0) + (other.reasoningTokens ?? 0),
    );
  }
}
