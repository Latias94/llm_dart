/// OpenAI-specific Responses API capability interface
///
/// This interface is specific to OpenAI's Responses API and provides
/// stateful conversation management, background processing, and
/// response lifecycle management.
///
/// Note: This is currently OpenAI-specific as other providers don't
/// yet support similar stateful conversation APIs.
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
    List<ChatMessage> messages,
    List<Tool>? tools,
  );

  /// Create a response with background processing
  ///
  /// When background=true, the response will be processed asynchronously.
  /// You can retrieve the result later using getResponse() or cancel it with cancelResponse().
  Future<ChatResponse> chatWithToolsBackground(
    List<ChatMessage> messages,
    List<Tool>? tools,
  );

  /// Stream chat responses with tools
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
  });

  // ========== Response Lifecycle Management ==========

  /// Retrieve a model response by ID
  ///
  /// This allows you to fetch a previously created response using its ID.
  /// Useful for stateful conversations and response chaining.
  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  });

  /// Delete a model response by ID
  ///
  /// Permanently removes a stored response from the provider's servers.
  /// Returns true if deletion was successful.
  Future<bool> deleteResponse(String responseId);

  /// Cancel a background response by ID
  ///
  /// Only responses created with background=true can be cancelled.
  /// Returns the cancelled response object.
  Future<ChatResponse> cancelResponse(String responseId);

  /// List input items for a response
  ///
  /// Returns the input items that were used to generate a specific response.
  /// Useful for debugging and understanding response context.
  Future<ResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  });

  // ========== Conversation State Management ==========

  /// Create a new response that continues from a previous response
  ///
  /// This enables stateful conversations where the provider maintains
  /// the conversation history automatically.
  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  });

  /// Fork a conversation from a specific response
  ///
  /// Creates a new conversation branch starting from the specified response.
  /// Useful for exploring different conversation paths.
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  });
}

/// Extension methods for OpenAIResponsesCapability
extension OpenAIResponsesCapabilityExtensions on OpenAIResponsesCapability {
  /// Convenience method for simple chat without tools
  Future<ChatResponse> chat(List<ChatMessage> messages) {
    return chatWithTools(messages, null);
  }

  /// Convenience method for background chat without tools
  Future<ChatResponse> chatBackground(List<ChatMessage> messages) {
    return chatWithToolsBackground(messages, null);
  }

  /// Check if a response exists and is accessible
  Future<bool> responseExists(String responseId) async {
    try {
      await getResponse(responseId);
      return true;
    } catch (e) {
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
