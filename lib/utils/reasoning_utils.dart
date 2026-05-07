/// Utilities for handling reasoning/thinking content in AI responses
/// This matches the logic from the TypeScript implementation
library;

/// Result of reasoning detection
class ReasoningDetectionResult {
  final bool isReasoningJustDone;
  final bool hasReasoningContent;
  final String updatedLastChunk;

  const ReasoningDetectionResult({
    required this.isReasoningJustDone,
    required this.hasReasoningContent,
    required this.updatedLastChunk,
  });
}

/// Utilities for handling reasoning/thinking content
class ReasoningUtils {
  /// Check if reasoning just finished based on delta content
  /// This matches the TypeScript isReasoningJustDone function
  static ReasoningDetectionResult checkReasoningStatus({
    required Map<String, dynamic>? delta,
    required bool hasReasoningContent,
    required String lastChunk,
  }) {
    // 如果有reasoning_content或reasoning或thinking，说明是在思考中
    bool updatedHasReasoningContent = hasReasoningContent;
    if (delta != null &&
        (delta['reasoning_content'] != null ||
            delta['reasoning'] != null ||
            delta['thinking'] != null)) {
      updatedHasReasoningContent = true;
    }

    if (delta == null || delta['content'] == null) {
      return ReasoningDetectionResult(
        isReasoningJustDone: false,
        hasReasoningContent: updatedHasReasoningContent,
        updatedLastChunk: lastChunk,
      );
    }

    final deltaContent = delta['content'] as String;

    // 检查当前chunk和上一个chunk的组合是否形成###Response标记
    final combinedChunks = lastChunk + deltaContent;
    final updatedLastChunk = deltaContent;

    // 检测思考结束
    if (combinedChunks.contains('###Response') || deltaContent == '</think>') {
      return ReasoningDetectionResult(
        isReasoningJustDone: true,
        hasReasoningContent: hasReasoningContent,
        updatedLastChunk: updatedLastChunk,
      );
    }

    // 如果之前有reasoning_content或reasoning，现在有普通content，说明思考结束
    if (hasReasoningContent && deltaContent.isNotEmpty) {
      return ReasoningDetectionResult(
        isReasoningJustDone: true,
        hasReasoningContent: updatedHasReasoningContent,
        updatedLastChunk: updatedLastChunk,
      );
    }

    return ReasoningDetectionResult(
      isReasoningJustDone: false,
      hasReasoningContent: updatedHasReasoningContent,
      updatedLastChunk: updatedLastChunk,
    );
  }

  /// Extract reasoning content from delta
  static String? extractReasoningContent(Map<String, dynamic>? delta) {
    if (delta == null) return null;

    return delta['reasoning_content'] as String? ??
        delta['reasoning'] as String? ??
        delta['thinking'] as String?;
  }

  /// Check if delta contains reasoning content
  static bool hasReasoningContent(Map<String, dynamic>? delta) {
    if (delta == null) return false;

    return delta['reasoning_content'] != null ||
        delta['reasoning'] != null ||
        delta['thinking'] != null;
  }

  /// Filter thinking content from text for display purposes
  /// Removes `<think>...</think>` tags and their content
  static String filterThinkingContent(String content) {
    // Remove <think>...</think> tags and their content
    return content
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        .trim();
  }

  /// Check if content contains thinking tags
  static bool containsThinkingTags(String content) {
    return content.contains('<think>') || content.contains('</think>');
  }

  /// Extract content without thinking tags
  static String extractContentWithoutThinking(String content) {
    // If content contains thinking tags, filter them out
    if (containsThinkingTags(content)) {
      return filterThinkingContent(content);
    }
    return content;
  }

  /// Parse reasoning metrics from response
  static Map<String, dynamic> parseReasoningMetrics({
    required DateTime startTime,
    DateTime? firstTokenTime,
    DateTime? firstContentTime,
    int? completionTokens,
  }) {
    final now = DateTime.now();
    final timeCompletionMs = now.difference(startTime).inMilliseconds;
    final timeFirstTokenMs =
        firstTokenTime?.difference(startTime).inMilliseconds ?? 0;
    final timeThinkingMs =
        firstContentTime?.difference(startTime).inMilliseconds ?? 0;

    return {
      'completion_tokens': completionTokens,
      'time_completion_millsec': timeCompletionMs,
      'time_first_token_millsec': timeFirstTokenMs,
      'time_thinking_millsec': timeThinkingMs,
    };
  }
}
