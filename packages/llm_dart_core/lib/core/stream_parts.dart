import 'dart:typed_data';

import 'capability.dart';
import 'cancellation.dart';
import 'llm_error.dart';
import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../prompt/prompt.dart';
import 'call_options.dart';

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

/// Response metadata emitted during streaming.
///
/// Mirrors Vercel AI SDK's `response-metadata` concept.
///
/// This part is intended for *stable, inspectable* metadata like response id
/// or model identifier, without forcing consumers to decode provider-specific
/// payloads from `providerMetadata`.
class LLMResponseMetadataPart extends LLMStreamPart {
  /// Provider response id (if available).
  final String? id;

  /// Timestamp for the start of the response (if available).
  ///
  /// Mirrors Vercel AI SDK's `response-metadata.timestamp` field.
  final DateTime? timestamp;

  /// Model identifier (if available).
  final String? model;

  /// Response headers (best-effort; HTTP providers only).
  ///
  /// Mirrors Vercel AI SDK's `LanguageModelResponseMetadata.headers` concept.
  final Map<String, String>? headers;

  /// Response body (best-effort; HTTP providers only).
  ///
  /// Mirrors Vercel AI SDK's `GenerateTextResult.response.body` field.
  final Object? body;

  /// Provider-specific response status (if applicable).
  final String? status;

  /// OpenAI-style system fingerprint (if available).
  final String? systemFingerprint;

  /// Optional provider metadata (namespaced) associated with this snapshot.
  final Map<String, dynamic>? providerMetadata;

  /// Optional raw snapshot for debugging (best-effort JSON-serializable map).
  final Map<String, dynamic>? raw;

  const LLMResponseMetadataPart({
    this.id,
    this.timestamp,
    this.model,
    this.headers,
    this.body,
    this.status,
    this.systemFingerprint,
    this.providerMetadata,
    this.raw,
  });
}

/// Request metadata emitted during streaming (best-effort).
///
/// This mirrors the AI SDK `LanguageModelRequestMetadata` concept and provides
/// a stable place to expose the HTTP request body that was sent to the model
/// provider (when available).
///
/// Notes:
/// - This is optional and provider-dependent.
/// - Providers should ensure [body] is JSON-serializable and does not contain
///   secrets or large/binary payloads.
class LLMRequestMetadataPart extends LLMStreamPart {
  /// Request HTTP body that was sent to the provider API (best-effort).
  final Object? body;

  const LLMRequestMetadataPart({this.body});
}

/// Optional interface for non-streaming responses that can expose response metadata.
///
/// This mirrors the AI SDK concept that `generateText` / `generateObject` results
/// include `response` metadata (including response headers when available).
abstract class ChatResponseWithResponseMetadata implements ChatResponse {
  LLMResponseMetadataPart? get responseMetadata;
}

/// Optional interface for non-streaming responses that can expose request metadata.
///
/// This mirrors the AI SDK concept that `generateText` / `generateObject` results
/// include `request` metadata (best-effort; provider-dependent).
abstract class ChatResponseWithRequestMetadata implements ChatResponse {
  LLMRequestMetadataPart? get requestMetadata;
}

/// Marks the start of a single "step" in a multi-step generation.
///
/// This mirrors the AI SDK concept of step results in `streamText`, where a
/// tool loop can perform multiple model calls (steps) before producing a final
/// response.
///
/// Notes:
/// - Providers typically do not emit step boundaries; orchestration layers
///   (tool loops) may inject them.
/// - This is intentionally lightweight and only carries a stable [stepIndex].
class LLMStepStartPart extends LLMStreamPart {
  /// 0-based step index within a single high-level request.
  final int stepIndex;

  const LLMStepStartPart(this.stepIndex) : assert(stepIndex >= 0);
}

/// Marks the end of a single "step" in a multi-step generation.
///
/// This is emitted by orchestration layers (e.g. local tool loops) once they
/// have:
/// - fully consumed the provider stream for the step, and
/// - (optionally) executed local tools and produced [toolResults].
///
/// It provides a stable hook for aggregating per-step results and computing
/// total usage across steps.
class LLMStepFinishPart extends LLMStreamPart {
  /// 0-based step index within a single high-level request.
  final int stepIndex;

  /// The raw provider response for this step.
  final ChatResponse response;

  /// Optional usage snapshot at step finish time.
  final UsageInfo? usage;

  /// Optional typed finish reason at step finish time.
  final LLMFinishReason? finishReason;

  /// Tool calls produced by the model for this step (local function tools only).
  final List<ToolCall> toolCalls;

  /// Tool results produced by local execution for this step.
  final List<ToolResult> toolResults;

  const LLMStepFinishPart({
    required this.stepIndex,
    required this.response,
    required this.toolCalls,
    required this.toolResults,
    this.usage,
    this.finishReason,
  }) : assert(stepIndex >= 0);
}

/// Optional capability for providers to emit `LLMStreamPart` directly.
///
/// Orchestration layers should prefer this capability for streaming.
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

/// Optional capability for parts-first streaming with per-call overrides.
///
/// This enables AI SDK-style request-level options (headers/body) for streaming
/// without mutating the global provider configuration.
abstract class ChatStreamPartsCallOptionsCapability {
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  });
}

/// Optional capability for prompt IR parts-first streaming with per-call overrides.
abstract class PromptChatStreamPartsCallOptionsCapability {
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
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

/// Starts a tool input block (AI SDK v3-style).
///
/// Tool inputs are streamed as string deltas, typically containing fragments of
/// stringified JSON objects.
///
/// This part mirrors AI SDK v3 `type: 'tool-input-start'`.
class LLMToolInputStartPart extends LLMStreamPart {
  /// Stable tool input id (typically the tool call id).
  final String id;

  /// The tool name that should be called.
  final String toolName;

  /// Optional provider metadata associated with this boundary.
  final Map<String, dynamic>? providerMetadata;

  /// Whether the tool will be executed by the provider (server-side).
  final bool? providerExecuted;

  /// Whether the tool is dynamic (defined at runtime, e.g. MCP tools).
  final bool? isDynamic;

  /// Optional human-readable title (best-effort).
  final String? title;

  const LLMToolInputStartPart({
    required this.id,
    required this.toolName,
    this.providerMetadata,
    this.providerExecuted,
    this.isDynamic,
    this.title,
  });
}

/// A delta/update within a tool input block (AI SDK v3-style).
///
/// Mirrors AI SDK v3 `type: 'tool-input-delta'`.
class LLMToolInputDeltaPart extends LLMStreamPart {
  final String id;
  final String delta;
  final Map<String, dynamic>? providerMetadata;

  const LLMToolInputDeltaPart({
    required this.id,
    required this.delta,
    this.providerMetadata,
  });
}

/// Ends a tool input block (AI SDK v3-style).
///
/// Mirrors AI SDK v3 `type: 'tool-input-end'`.
class LLMToolInputEndPart extends LLMStreamPart {
  final String id;
  final Map<String, dynamic>? providerMetadata;

  const LLMToolInputEndPart({
    required this.id,
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

/// Raw passthrough stream part.
///
/// Mirrors the AI SDK v3 `raw` part when raw chunks are enabled.
/// Consumers should treat [rawValue] as an opaque, best-effort JSON-like value.
class LLMRawPart extends LLMStreamPart {
  final Object? rawValue;
  const LLMRawPart(this.rawValue);
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

  /// Whether the tool call will be executed by the provider.
  ///
  /// Mirrors AI SDK v3 `tool-call.providerExecuted`. Defaults to `true` for
  /// provider-native tools, but can be set to `false` for provider-triggered
  /// client-executed tools (e.g. "local shell" style calls).
  final bool? providerExecuted;

  /// Whether this provider tool may return its results in a later step/turn.
  ///
  /// This is an orchestration hint aligned with AI SDK's
  /// `supportsDeferredResults` provider tool property.
  ///
  /// When `true`, higher-level loops may continue even when the current step
  /// produced no client-side tool calls, in order to wait for a non-preliminary
  /// tool result in a subsequent step.
  final bool? supportsDeferredResults;

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
    this.providerExecuted,
    this.supportsDeferredResults,
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

/// A file generated by the model.
///
/// Mirrors AI SDK v3 `type: 'file'` stream parts.
///
/// Note: [data] is intentionally flexible to avoid unnecessary conversions:
/// - If a provider returns base64 strings, keep it as [String].
/// - If a provider returns raw bytes, keep it as [Uint8List].
class LLMFilePart extends LLMStreamPart {
  /// IANA media type of the file, e.g. `image/png`.
  final String mediaType;

  /// File data as base64 string or raw bytes.
  final Object data;

  /// Optional provider metadata for this file.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  final Map<String, dynamic>? providerMetadata;

  const LLMFilePart({
    required this.mediaType,
    required this.data,
    this.providerMetadata,
  }) : assert(data is String || data is Uint8List,
            'LLMFilePart.data must be a String (base64) or Uint8List (bytes)');
}

/// A successful completion for the streamed request.
class LLMFinishPart extends LLMStreamPart {
  final ChatResponse response;

  /// Optional usage snapshot at finish time.
  ///
  /// This mirrors AI SDK's `finish.usage` shape and avoids forcing consumers
  /// to parse provider metadata for token counts.
  final UsageInfo? usage;

  /// Optional typed finish reason at finish time.
  ///
  /// When present, this is best-effort provider-agnostic mapping.
  final LLMFinishReason? finishReason;

  const LLMFinishPart(
    this.response, {
    this.usage,
    this.finishReason,
  });
}

/// A terminal error emitted by the provider or orchestration layer.
class LLMErrorPart extends LLMStreamPart {
  final LLMError error;
  const LLMErrorPart(this.error);
}

/// An error part that preserves the raw v3 error payload.
///
/// This mirrors AI SDK v3 `type: 'error'` stream parts, where `error` is an
/// unknown JSON-like payload. This is primarily used by the v3 fixture codec
/// to keep decode -> encode round-trips stable even when providers include
/// additional fields.
class LLMErrorRawPart extends LLMStreamPart {
  /// Raw error payload from the v3 stream.
  final Object? rawError;

  /// Best-effort typed error decoded from [rawError], if possible.
  final LLMError? decodedError;

  const LLMErrorRawPart(this.rawError, {this.decodedError});
}
