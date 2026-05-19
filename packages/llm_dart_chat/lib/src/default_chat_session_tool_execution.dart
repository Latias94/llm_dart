import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_session.dart';
import 'chat_session_tool_support.dart';
import 'chat_state.dart';

typedef ChatToolOutputApplier = Future<void> Function(
  ToolOutputUpdate update,
);

final class DefaultChatSessionToolExecutionScheduler {
  final ChatOnToolCall? onToolCall;
  final bool Function() isDisposed;
  final bool Function() hasActiveTurn;
  final ChatState Function() readState;
  final ChatToolOutputApplier applyToolOutput;
  final Set<String> _scheduledToolExecutionKeys = <String>{};

  DefaultChatSessionToolExecutionScheduler({
    required this.onToolCall,
    required this.isDisposed,
    required this.hasActiveTurn,
    required this.readState,
    required this.applyToolOutput,
  });

  void maybeSchedule() {
    final handler = onToolCall;
    final state = readState();
    if (handler == null ||
        isDisposed() ||
        hasActiveTurn() ||
        state.status != ChatStatus.awaitingTool) {
      return;
    }

    final assistantMessage = latestAssistantMessageOrNull(state);
    if (assistantMessage == null) {
      return;
    }

    for (final part in chatPendingAutomaticToolParts(assistantMessage)) {
      final executionKey =
          _toolExecutionKey(assistantMessage.id, part.toolCallId);
      if (!_scheduledToolExecutionKeys.add(executionKey)) {
        continue;
      }

      final request = ToolExecutionRequest(
        chatId: state.chatId,
        messageId: assistantMessage.id,
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        input: part.input,
        inputText: part.inputText,
        isDynamic: part.isDynamic,
        title: part.title,
        approval: part.approval,
        callProviderMetadata: part.callProviderMetadata,
      );

      unawaited(_runAutomaticToolExecution(handler, request));
    }
  }

  Future<void> _runAutomaticToolExecution(
    ChatOnToolCall handler,
    ToolExecutionRequest request,
  ) async {
    ToolExecutionResult? result;

    try {
      result = await handler(request);
    } catch (error) {
      result = ToolExecutionResult.error(
        'Automatic tool execution failed for "${request.toolName}": $error',
      );
    }

    if (result == null ||
        !canApplyAutomaticToolOutput(
          isDisposed: isDisposed(),
          hasActiveTurn: hasActiveTurn(),
          state: readState(),
          toolCallId: request.toolCallId,
        )) {
      return;
    }

    try {
      await applyToolOutput(
        ToolOutputUpdate(
          toolCallId: request.toolCallId,
          toolName: request.toolName,
          toolOutput: result.toolOutput,
          options: result.options,
        ),
      );
    } on StateError {
      if (canApplyAutomaticToolOutput(
        isDisposed: isDisposed(),
        hasActiveTurn: hasActiveTurn(),
        state: readState(),
        toolCallId: request.toolCallId,
      )) {
        rethrow;
      }
    }
  }
}

ChatUiMessage? latestAssistantMessageOrNull(ChatState state) {
  if (state.messages.isEmpty ||
      state.messages.last.role != ChatUiRole.assistant) {
    return null;
  }

  return state.messages.last;
}

bool canApplyAutomaticToolOutput({
  required bool isDisposed,
  required bool hasActiveTurn,
  required ChatState state,
  required String toolCallId,
}) {
  if (isDisposed || hasActiveTurn || state.status != ChatStatus.awaitingTool) {
    return false;
  }

  final assistantMessage = latestAssistantMessageOrNull(state);
  if (assistantMessage == null) {
    return false;
  }

  for (final part in assistantMessage.parts.whereType<ToolUiPart>()) {
    if (part.toolCallId != toolCallId) {
      continue;
    }

    return !part.providerExecuted &&
        (part.state == ToolUiPartState.inputAvailable ||
            part.state == ToolUiPartState.inputStreaming ||
            part.state == ToolUiPartState.approvalResponded);
  }

  return false;
}

String _toolExecutionKey(String messageId, String toolCallId) {
  return '$messageId\u0000$toolCallId';
}
