/// Compatibility helpers for reasoning/thinking content in provider responses.
library;

/// Result of reasoning detection.
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

/// Internal compatibility utilities for reasoning/thinking content.
class CompatReasoningUtils {
  /// Check if reasoning just finished based on delta content.
  static ReasoningDetectionResult checkReasoningStatus({
    required Map<String, dynamic>? delta,
    required bool hasReasoningContent,
    required String lastChunk,
  }) {
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

    final combinedChunks = lastChunk + deltaContent;
    final updatedLastChunk = deltaContent;

    if (combinedChunks.contains('###Response') || deltaContent == '</think>') {
      return ReasoningDetectionResult(
        isReasoningJustDone: true,
        hasReasoningContent: hasReasoningContent,
        updatedLastChunk: updatedLastChunk,
      );
    }

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

  /// Extract reasoning content from delta.
  static String? extractReasoningContent(Map<String, dynamic>? delta) {
    if (delta == null) return null;

    return delta['reasoning_content'] as String? ??
        delta['reasoning'] as String? ??
        delta['thinking'] as String?;
  }

  /// Check if delta contains reasoning content.
  static bool hasReasoningContent(Map<String, dynamic>? delta) {
    if (delta == null) return false;

    return delta['reasoning_content'] != null ||
        delta['reasoning'] != null ||
        delta['thinking'] != null;
  }

  /// Remove complete `<think>...</think>` blocks from display text.
  static String filterThinkingContent(String content) {
    return content
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        .trim();
  }

  /// Check if content contains thinking tags.
  static bool containsThinkingTags(String content) {
    return content.contains('<think>') || content.contains('</think>');
  }
}
