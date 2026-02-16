import 'package:llm_dart_core/llm_dart_core.dart';

/// Additional context passed into each local tool execution.
///
/// This mirrors the spirit of Vercel AI SDK `ToolExecutionOptions`, but keeps
/// Dart/llm_dart specifics:
/// - [cancelToken] is used instead of AbortSignal.
/// - [stepIndex] is included for tool loop orchestration.
/// - [toolName]/[rawArguments]/[toolCall] are included for diagnostics.
///
/// Notes:
/// - [messages] are the messages that initiated the assistant response that
///   contained the tool call. They do not include the assistant response that
///   contained the tool call itself.
/// - [messages] are provided as an unmodifiable list; treat them as immutable.
final class ToolExecutionOptions {
  /// The id of the tool call.
  final String toolCallId;

  /// The tool name being executed.
  final String toolName;

  /// Raw tool arguments string, as emitted by the model.
  final String rawArguments;

  /// Messages that initiated the response that contained the tool call.
  final List<ChatMessage> messages;

  /// Tool loop step index (best-effort).
  final int stepIndex;

  /// Optional cancellation token for aborting execution.
  final CancelToken? cancelToken;

  /// User-defined context (experimental; may change).
  final Object? experimentalContext;

  /// The original tool call object (best-effort).
  final ToolCall toolCall;

  const ToolExecutionOptions({
    required this.toolCallId,
    required this.toolName,
    required this.rawArguments,
    required this.messages,
    required this.stepIndex,
    required this.toolCall,
    this.cancelToken,
    this.experimentalContext,
  });
}
