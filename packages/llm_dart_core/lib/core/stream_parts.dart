import 'capability.dart';
import 'cancellation.dart';
import 'llm_error.dart';
import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../prompt/prompt.dart';

/// Provider-agnostic stream parts (Vercel-style).
///
/// This is a forward-compatible, structured representation of streaming output.
/// Providers may emit richer parts over time; orchestration layers can adapt
/// legacy streams to these parts.
sealed class LLMStreamPart {
  const LLMStreamPart();
}

/// Optional capability for providers to emit `LLMStreamPart` directly.
///
/// If a provider implements this, orchestration layers can prefer it over the
/// legacy `ChatStreamEvent` adapter.
abstract class ChatStreamPartsCapability {
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  });
}

/// Optional capability for providers to stream `LLMStreamPart` from `Prompt` IR
/// directly (without forcing `Prompt.toChatMessages()`).
abstract class PromptChatStreamPartsCapability {
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  });
}

/// Starts a text block.
class LLMTextStartPart extends LLMStreamPart {
  const LLMTextStartPart();
}

/// A delta within the current text block.
class LLMTextDeltaPart extends LLMStreamPart {
  final String delta;
  const LLMTextDeltaPart(this.delta);
}

/// Ends a text block.
class LLMTextEndPart extends LLMStreamPart {
  /// Best-effort full text accumulated for this block.
  final String text;
  const LLMTextEndPart(this.text);
}

/// Starts a reasoning/thinking block.
class LLMReasoningStartPart extends LLMStreamPart {
  const LLMReasoningStartPart();
}

/// A delta within the current reasoning/thinking block.
class LLMReasoningDeltaPart extends LLMStreamPart {
  final String delta;
  const LLMReasoningDeltaPart(this.delta);
}

/// Ends a reasoning/thinking block.
class LLMReasoningEndPart extends LLMStreamPart {
  /// Best-effort full reasoning accumulated for this block.
  final String thinking;
  const LLMReasoningEndPart(this.thinking);
}

/// Starts a tool call (arguments are usually streamed progressively).
class LLMToolCallStartPart extends LLMStreamPart {
  final ToolCall toolCall;
  const LLMToolCallStartPart(this.toolCall);
}

/// A delta/update for a tool call.
class LLMToolCallDeltaPart extends LLMStreamPart {
  final ToolCall toolCall;
  const LLMToolCallDeltaPart(this.toolCall);
}

/// Ends a tool call stream (best-effort signal at end-of-step).
class LLMToolCallEndPart extends LLMStreamPart {
  final String toolCallId;
  const LLMToolCallEndPart(this.toolCallId);
}

/// Tool execution result (typically produced by local tool loops).
class LLMToolResultPart extends LLMStreamPart {
  final ToolResult result;
  const LLMToolResultPart(this.result);
}

/// Provider-specific metadata that should not expand the standard surface.
class LLMProviderMetadataPart extends LLMStreamPart {
  final Map<String, dynamic> providerMetadata;
  const LLMProviderMetadataPart(this.providerMetadata);
}

/// A successful completion for the streamed request.
class LLMFinishPart extends LLMStreamPart {
  final ChatResponse response;
  const LLMFinishPart(this.response);
}

/// A terminal error emitted by the provider or orchestration layer.
class LLMErrorPart extends LLMStreamPart {
  final LLMError error;
  const LLMErrorPart(this.error);
}
