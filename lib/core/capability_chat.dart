part of 'capability.dart';

/// Response from a chat provider
abstract class ChatResponse {
  /// Get the text content of the response
  String? get text;

  /// Get tool calls from the response
  List<ToolCall>? get toolCalls;

  /// Get thinking/reasoning content (for providers that support it)
  String? get thinking => null;

  /// Get usage information if available
  UsageInfo? get usage => null;
}

/// Core chat capability interface that most LLM providers implement
abstract class ChatCapability {
  /// Sends a chat request to the provider with a sequence of messages.
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  /// Sends a chat request to the provider with a sequence of messages and tools.
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  });

  /// Sends a streaming chat request to the provider
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  });

  /// Get current memory contents if provider supports memory
  Future<List<ChatMessage>?> memoryContents() async => null;

  /// Summarizes a conversation history into a concise 2-3 sentence summary
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final request = [ChatMessage.user(prompt)];
    final response = await chat(request);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }
}

/// Stream event for streaming chat responses
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

/// Text delta event
class TextDeltaEvent extends ChatStreamEvent {
  final String delta;

  const TextDeltaEvent(this.delta);
}

/// Tool call delta event
class ToolCallDeltaEvent extends ChatStreamEvent {
  final ToolCall toolCall;

  const ToolCallDeltaEvent(this.toolCall);
}

/// Completion event
class CompletionEvent extends ChatStreamEvent {
  final ChatResponse response;

  const CompletionEvent(this.response);
}

/// Thinking/reasoning delta event for reasoning models
class ThinkingDeltaEvent extends ChatStreamEvent {
  final String delta;

  const ThinkingDeltaEvent(this.delta);
}

/// Error event
class ErrorEvent extends ChatStreamEvent {
  final LLMError error;

  const ErrorEvent(this.error);
}

/// Enhanced chat capability with advanced tool and output control
abstract class EnhancedChatCapability extends ChatCapability {
  /// Sends a chat request with advanced tool and output configuration
  Future<ChatResponse> chatWithAdvancedTools(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? structuredOutput,
  });

  /// Sends a streaming chat request with advanced tool and output configuration
  Stream<ChatStreamEvent> chatStreamWithAdvancedTools(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? structuredOutput,
  });
}
