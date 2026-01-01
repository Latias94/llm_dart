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
