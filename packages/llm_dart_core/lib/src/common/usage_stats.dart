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

  bool get isEmpty =>
      inputTokens == null &&
      outputTokens == null &&
      totalTokens == null &&
      reasoningTokens == null;

  bool get isNotEmpty => !isEmpty;

  UsageStats mergedWith(UsageStats? other) {
    if (other == null || other.isEmpty) {
      return this;
    }

    if (isEmpty) {
      return other;
    }

    return UsageStats(
      inputTokens: _mergeTokenCount(inputTokens, other.inputTokens),
      outputTokens: _mergeTokenCount(outputTokens, other.outputTokens),
      totalTokens: _mergeTokenCount(totalTokens, other.totalTokens),
      reasoningTokens: _mergeTokenCount(
        reasoningTokens,
        other.reasoningTokens,
      ),
    );
  }

  UsageStats operator +(UsageStats other) {
    return mergedWith(other);
  }

  static UsageStats? mergeNullable(
    UsageStats? left,
    UsageStats? right,
  ) {
    if (left == null || left.isEmpty) {
      return right == null || right.isEmpty ? null : right;
    }

    return left.mergedWith(right);
  }

  @override
  bool operator ==(Object other) {
    return other is UsageStats &&
        other.inputTokens == inputTokens &&
        other.outputTokens == outputTokens &&
        other.totalTokens == totalTokens &&
        other.reasoningTokens == reasoningTokens;
  }

  @override
  int get hashCode => Object.hash(
        inputTokens,
        outputTokens,
        totalTokens,
        reasoningTokens,
      );

  @override
  String toString() {
    return 'UsageStats('
        'inputTokens: $inputTokens, '
        'outputTokens: $outputTokens, '
        'totalTokens: $totalTokens, '
        'reasoningTokens: $reasoningTokens'
        ')';
  }
}

int? _mergeTokenCount(
  int? left,
  int? right,
) {
  if (left == null) {
    return right;
  }

  if (right == null) {
    return left;
  }

  return left + right;
}
