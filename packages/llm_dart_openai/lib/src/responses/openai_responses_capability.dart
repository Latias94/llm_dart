/// OpenAI-specific Responses API capability interface for the subpackage.
library;

import 'package:llm_dart_core/llm_dart_core.dart';

/// OpenAI-specific capability interface for stateful Responses API
///
/// This interface extends beyond basic chat capabilities to provide
/// stateful conversation management, background processing, and
/// response lifecycle management specific to OpenAI's Responses API.
abstract class OpenAIResponsesCapability {
  // ========== Basic Chat Operations ==========

  /// Create a response with tools support
  Future<ChatResponse> chatWithTools(
    List<ModelMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  });

  /// Create a response with background processing
  Future<ChatResponse> chatWithToolsBackground(
    List<ModelMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
  });

  /// Stream chat responses with tools
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  });

  // ========== Response Lifecycle Management ==========

  /// Retrieve a model response by ID
  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  });

  /// Delete a model response by ID
  Future<bool> deleteResponse(String responseId);

  /// Cancel a background response by ID
  Future<ChatResponse> cancelResponse(String responseId);

  /// List input items for a response
  Future<ResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit,
    String order,
  });

  // ========== Conversation State Management ==========

  /// Create a new response that continues from a previous response
  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ModelMessage> newMessages, {
    List<Tool>? tools,
    bool background,
  });

  /// Fork a conversation from a specific response
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ModelMessage> newMessages, {
    List<Tool>? tools,
    bool background,
  });
}

/// Extension methods for OpenAIResponsesCapability
extension OpenAIResponsesCapabilityExtensions on OpenAIResponsesCapability {
  /// Convenience method for simple chat without tools
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return chatWithTools(
      messages,
      null,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Convenience method for background chat without tools
  Future<ChatResponse> chatBackground(
    List<ModelMessage> messages, {
    LanguageModelCallOptions? options,
  }) {
    return chatWithToolsBackground(
      messages,
      null,
      options: options,
    );
  }

  /// Check if a response exists and is accessible
  Future<bool> responseExists(String responseId) async {
    try {
      await getResponse(responseId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get response text directly
  Future<String?> getResponseText(String responseId) async {
    final response = await getResponse(responseId);
    return response.text;
  }

  /// Get response thinking content directly
  Future<String?> getResponseThinking(String responseId) async {
    final response = await getResponse(responseId);
    return response.thinking;
  }
}
