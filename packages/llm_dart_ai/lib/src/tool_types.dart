import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// A handler for executing a tool call locally.
typedef ToolCallHandler = FutureOr<Object?> Function(
  ToolCall toolCall, {
  CancelToken? cancelToken,
});

/// A predicate for determining whether a tool call needs user approval.
///
/// If it returns `true`, a tool loop can stop early and surface a
/// "tool approval required" state to the caller.
typedef ToolApprovalCheck = FutureOr<bool> Function(
  ToolCall toolCall, {
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
  ToolCall toolCall, {
  required String reason,
  String? errorMessage,
  List<String>? validationErrors,
});
