/// Shared usage accounting models.
library;

class UsageInfo {
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final int? reasoningTokens;

  const UsageInfo({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.reasoningTokens,
  });

  /// Adds two UsageInfo instances together for token usage accumulation.
  UsageInfo operator +(UsageInfo other) {
    return UsageInfo(
      promptTokens: (promptTokens ?? 0) + (other.promptTokens ?? 0),
      completionTokens: (completionTokens ?? 0) + (other.completionTokens ?? 0),
      totalTokens: (totalTokens ?? 0) + (other.totalTokens ?? 0),
      reasoningTokens: (reasoningTokens ?? 0) + (other.reasoningTokens ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        if (promptTokens != null) 'prompt_tokens': promptTokens,
        if (completionTokens != null) 'completion_tokens': completionTokens,
        if (totalTokens != null) 'total_tokens': totalTokens,
        if (reasoningTokens != null) 'reasoning_tokens': reasoningTokens,
      };

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
        promptTokens: json['prompt_tokens'] as int?,
        completionTokens: json['completion_tokens'] as int?,
        totalTokens: json['total_tokens'] as int?,
        reasoningTokens: json['reasoning_tokens'] as int?,
      );

  @override
  String toString() {
    final parts = <String>[];
    if (promptTokens != null) parts.add('prompt: $promptTokens');
    if (completionTokens != null) parts.add('completion: $completionTokens');
    if (reasoningTokens != null) parts.add('reasoning: $reasoningTokens');
    if (totalTokens != null) parts.add('total: $totalTokens');
    return 'UsageInfo(${parts.join(', ')})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageInfo &&
          runtimeType == other.runtimeType &&
          promptTokens == other.promptTokens &&
          completionTokens == other.completionTokens &&
          totalTokens == other.totalTokens &&
          reasoningTokens == other.reasoningTokens;

  @override
  int get hashCode =>
      Object.hash(promptTokens, completionTokens, totalTokens, reasoningTokens);
}
