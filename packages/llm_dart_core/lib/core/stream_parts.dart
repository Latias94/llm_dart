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

/// Marks the start of a streaming response.
///
/// Mirrors Vercel AI SDK's `stream-start` concept and provides a stable place
/// to surface warnings or other non-token metadata without overloading
/// providerMetadata maps.
class LLMStreamStartPart extends LLMStreamPart {
  /// Optional warnings emitted by the orchestration layer or provider.
  ///
  /// Best-effort structure aligned with AI SDK warnings (typically objects).
  final List<Map<String, dynamic>> warnings;

  const LLMStreamStartPart({this.warnings = const []});
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
  /// Optional block id to represent multiple output blocks (AI SDK style).
  final String? blockId;

  /// Optional provider metadata associated with this block boundary.
  final Map<String, dynamic>? providerMetadata;

  const LLMTextStartPart({this.blockId, this.providerMetadata});
}

/// A delta within the current text block.
class LLMTextDeltaPart extends LLMStreamPart {
  final String delta;

  /// Optional block id to represent multiple output blocks (AI SDK style).
  final String? blockId;

  /// Optional provider metadata associated with this delta.
  final Map<String, dynamic>? providerMetadata;

  const LLMTextDeltaPart(
    this.delta, {
    this.blockId,
    this.providerMetadata,
  });
}

/// Ends a text block.
class LLMTextEndPart extends LLMStreamPart {
  /// Best-effort full text accumulated for this block.
  final String text;

  /// Optional block id to represent multiple output blocks (AI SDK style).
  final String? blockId;

  /// Optional provider metadata associated with this block boundary.
  final Map<String, dynamic>? providerMetadata;

  const LLMTextEndPart(
    this.text, {
    this.blockId,
    this.providerMetadata,
  });
}

/// Starts a reasoning/thinking block.
class LLMReasoningStartPart extends LLMStreamPart {
  /// Optional block id to represent multiple output blocks (AI SDK style).
  final String? blockId;

  /// Optional provider metadata associated with this block boundary.
  final Map<String, dynamic>? providerMetadata;

  const LLMReasoningStartPart({this.blockId, this.providerMetadata});
}

/// A delta within the current reasoning/thinking block.
class LLMReasoningDeltaPart extends LLMStreamPart {
  final String delta;

  /// Optional block id to represent multiple output blocks (AI SDK style).
  final String? blockId;

  /// Optional provider metadata associated with this delta.
  final Map<String, dynamic>? providerMetadata;

  const LLMReasoningDeltaPart(
    this.delta, {
    this.blockId,
    this.providerMetadata,
  });
}

/// Ends a reasoning/thinking block.
class LLMReasoningEndPart extends LLMStreamPart {
  /// Best-effort full reasoning accumulated for this block.
  final String thinking;

  /// Optional block id to represent multiple output blocks (AI SDK style).
  final String? blockId;

  /// Optional provider metadata associated with this block boundary.
  final Map<String, dynamic>? providerMetadata;

  const LLMReasoningEndPart(
    this.thinking, {
    this.blockId,
    this.providerMetadata,
  });
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

/// A tool call that will be executed by the provider (server-side).
///
/// This mirrors the Vercel AI SDK "tool-call" with `providerExecuted=true`,
/// but uses a dedicated part type to avoid accidental execution in local tool
/// loops that only handle function tools.
class LLMProviderToolCallPart extends LLMStreamPart {
  /// Provider-stable tool call id within a single response.
  final String toolCallId;

  /// Provider tool name (e.g. `web_search`, `file_search`).
  final String toolName;

  /// Tool input payload (best-effort JSON-serializable object).
  ///
  /// Some providers encode inputs as a stringified JSON object.
  final Object? input;

  /// Whether the tool is dynamic (defined at runtime).
  final bool? isDynamic;

  /// Optional provider metadata for this tool call.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  final Map<String, dynamic>? providerMetadata;

  const LLMProviderToolCallPart({
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.isDynamic,
    this.providerMetadata,
  });
}

/// A status/progress update for a provider-executed tool call (server-side).
///
/// Providers may emit additional lifecycle events between call and final result
/// (e.g. `in_progress`, `searching`, `interpreting`).
class LLMProviderToolDeltaPart extends LLMStreamPart {
  /// Tool call id that this update is associated with.
  final String toolCallId;

  /// Provider tool name (e.g. `web_search`, `file_search`).
  final String toolName;

  /// Provider-defined status string (e.g. `in_progress`, `searching`).
  final String status;

  /// Optional JSON-serializable payload for this update.
  final Object? data;

  /// Optional provider metadata for this tool update.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  final Map<String, dynamic>? providerMetadata;

  const LLMProviderToolDeltaPart({
    required this.toolCallId,
    required this.toolName,
    required this.status,
    this.data,
    this.providerMetadata,
  });
}

/// Tool approval request emitted by a provider for a provider-executed tool call.
///
/// This mirrors the Vercel AI SDK "tool-approval-request" concept.
class LLMProviderToolApprovalRequestPart extends LLMStreamPart {
  /// ID of the approval request. This ID should be referenced by a subsequent
  /// provider-native approval response (provider/protocol-specific).
  final String approvalId;

  /// Provider-stable tool call id within a single response.
  ///
  /// Some providers do not distinguish approvalId vs toolCallId; in that case
  /// they may be identical.
  final String toolCallId;

  /// Provider tool name (e.g. MCP tool name).
  final String toolName;

  /// Tool input payload (best-effort JSON-serializable object).
  final Object? input;

  /// Optional provider metadata for this approval request.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  final Map<String, dynamic>? providerMetadata;

  const LLMProviderToolApprovalRequestPart({
    required this.approvalId,
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.providerMetadata,
  });
}

/// Result of a tool call that has been executed by the provider (server-side).
///
/// This mirrors the Vercel AI SDK "tool-result" concept.
class LLMProviderToolResultPart extends LLMStreamPart {
  /// Tool call id that this result is associated with.
  final String toolCallId;

  /// Provider tool name (e.g. `web_search`, `file_search`).
  final String toolName;

  /// Result payload (best-effort JSON-serializable object).
  final Object? result;

  /// Optional flag if the result is an error.
  final bool? isError;

  /// Whether the tool result is preliminary (e.g. previews).
  final bool? preliminary;

  /// Whether the tool is dynamic (defined at runtime).
  final bool? isDynamic;

  /// Optional provider metadata for this tool result.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  final Map<String, dynamic>? providerMetadata;

  const LLMProviderToolResultPart({
    required this.toolCallId,
    required this.toolName,
    this.result,
    this.isError,
    this.preliminary,
    this.isDynamic,
    this.providerMetadata,
  });
}

/// A URL source that has been used as input to generate the response.
///
/// This mirrors the Vercel AI SDK "source-url" concept.
class LLMSourceUrlPart extends LLMStreamPart {
  /// Provider-stable source id within a single response.
  final String sourceId;

  /// The URL of the source.
  final String url;

  /// Optional human-readable title for the source.
  final String? title;

  /// Optional provider metadata for this source.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  final Map<String, dynamic>? providerMetadata;

  const LLMSourceUrlPart({
    required this.sourceId,
    required this.url,
    this.title,
    this.providerMetadata,
  });
}

/// A document source that has been used as input to generate the response.
///
/// This mirrors the Vercel AI SDK "source-document" concept.
class LLMSourceDocumentPart extends LLMStreamPart {
  /// Provider-stable source id within a single response.
  final String sourceId;

  /// IANA media type of the document (e.g. `application/pdf`).
  final String mediaType;

  /// Human-readable title for the document.
  final String title;

  /// Optional filename for the document.
  final String? filename;

  /// Optional provider metadata for this source.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  final Map<String, dynamic>? providerMetadata;

  const LLMSourceDocumentPart({
    required this.sourceId,
    required this.mediaType,
    required this.title,
    this.filename,
    this.providerMetadata,
  });
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
