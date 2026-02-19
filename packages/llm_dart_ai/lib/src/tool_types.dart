import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'tool_execution_options.dart';

/// A handler for executing a tool call locally.
typedef ToolCallHandler = FutureOr<Object?> Function(
  Map<String, dynamic> input,
  ToolExecutionOptions options,
);

/// Optional conversion function that maps a tool execution output to a v3
/// `tool-result` output envelope.
///
/// This mirrors Vercel AI SDK's `toModelOutput` concept (used by dynamic tools),
/// but keeps Dart's local execution model:
/// - [input] is the parsed JSON object tool arguments,
/// - [output] is whatever the tool handler returned,
/// - return a [ToolResultOutput] to control how the result is represented to
///   the model (text/json/content/error/denied).
typedef ToolToModelOutput = FutureOr<ToolResultOutput> Function({
  required String toolCallId,
  required Map<String, dynamic> input,
  required Object? output,
  required ToolExecutionOptions options,
});

/// Callback invoked when tool input streaming starts for a tool call.
typedef ToolInputStartHandler = FutureOr<void> Function(
  String toolCallId,
);

/// Callback invoked for each streamed tool input delta.
typedef ToolInputDeltaHandler = FutureOr<void> Function(
  String toolCallId,
  String inputTextDelta,
);

/// Callback invoked when full tool input becomes available (best-effort).
typedef ToolInputAvailableHandler = FutureOr<void> Function(
  String toolCallId,
  Object? input,
);

/// Callback invoked when tool input is available but invalid (best-effort).
typedef ToolInputErrorHandler = FutureOr<void> Function(
  String toolCallId,
  Object? input,
  String errorText,
);

/// A predicate for determining whether a tool call needs user approval.
///
/// If it returns `true`, a tool loop can stop early and surface a
/// "tool approval required" state to the caller.
typedef ToolApprovalCheck = FutureOr<bool> Function(
  V3ToolCall toolCall, {
  required List<ChatMessage> messages,
  required int stepIndex,
  CancelToken? cancelToken,
});

/// A hook for repairing an invalid tool call before local execution.
///
/// This is intended for "fearless refactors" where providers/models may emit
/// malformed tool arguments (e.g. truncated JSON) during streaming.
///
/// Contract:
/// - Return a repaired JSON string (must decode to a JSON object) to retry parsing/validation.
/// - Return `null` to keep the default behavior (emit an error tool result and skip execution).
///
/// [reason] values are stable and may be used for metrics:
/// - `invalid_json`
/// - `arguments_not_object`
/// - `schema_validation_failed`
typedef ToolCallRepair = FutureOr<String?> Function(
  V3ToolCall toolCall, {
  required String reason,
  String? errorMessage,
  List<String>? validationErrors,
});

/// How tool input/output schemas should be applied in local tool execution.
///
/// This mirrors Vercel AI SDK's `schemas` option (e.g. `'automatic' | 'none'`).
enum ToolSchemas {
  /// Use available schemas automatically (when present).
  automatic,

  /// Disable schema usage (best-effort mode).
  none,
}
