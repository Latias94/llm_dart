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
    // If there is reasoning_content / reasoning / thinking, we are currently in
    // a reasoning phase.
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

    // Check whether the combination of the previous chunk and the current chunk
    // forms a `###Response` marker.
    final combinedChunks = lastChunk + deltaContent;
    final updatedLastChunk = deltaContent;

    // Detect the end of the reasoning phase.
    if (combinedChunks.contains('###Response') || deltaContent == '</think>') {
      return ReasoningDetectionResult(
        isReasoningJustDone: true,
        hasReasoningContent: hasReasoningContent,
        updatedLastChunk: updatedLastChunk,
      );
    }

    // If we previously saw reasoning_content / reasoning and now we see regular
    // content, we treat this as the reasoning phase having finished.
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

  /// Check if the model is an OpenAI reasoning model.
  ///
  /// This follows the same semantics as the TypeScript implementation:
  /// - Non-reasoning chat models like gpt-3.*, gpt-4.*, chatgpt-4o, gpt-5-chat*
  ///   are treated as standard models.
  /// - All other OpenAI models (o1/o3/o4 series, GPT‑5 family, etc.) are
  ///   treated as reasoning models and use `max_completion_tokens` instead
  ///   of `max_tokens` and may have stricter parameter support.
  static bool isOpenAIReasoningModel(String model) {
    final id = model.toLowerCase();

    // Explicit non-reasoning chat families
    if (id.startsWith('gpt-3')) return false;
    if (id.startsWith('gpt-4')) return false;
    if (id.startsWith('chatgpt-4o')) return false;
    if (id.startsWith('gpt-5-chat')) return false;

    // Everything else (o1/o3/o4, gpt-5, gpt-5.1, gpt-5-mini/nano/pro, etc.)
    return true;
  }

  /// Check if the model is known to support reasoning (broader check)
  /// This is a hint for UI behavior, but actual reasoning detection
  /// should be based on response content, not model name
  static bool isKnownReasoningModel(String model) {
    final id = model.toLowerCase();

    // Restrict OpenAI reasoning detection to known OpenAI-style ids
    final isOpenAIModel = id.startsWith('gpt-') ||
        id.startsWith('o1') ||
        id.startsWith('o3') ||
        id.startsWith('o4');

    final isOpenAIReasoning = isOpenAIModel && isOpenAIReasoningModel(model);

    return isOpenAIReasoning ||
        model == 'deepseek-reasoner' ||
        model == 'deepseek-r1' ||
        model.contains('claude-3.7-sonnet') ||
        model.contains('claude-opus-4') ||
        model.contains('claude-sonnet-4') ||
        model.contains('qwen') && model.contains('reasoning') ||
        id.contains('reasoning') ||
        id.contains('thinking');
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
