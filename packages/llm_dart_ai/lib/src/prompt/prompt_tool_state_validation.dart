import 'package:llm_dart_provider/llm_dart_provider.dart';

final class PromptToolStateValidator {
  final String context;
  final Map<String, _ToolCallState> _seenToolCalls = {};
  final Map<String, _ToolCallState> _pendingClientToolCalls = {};
  final Map<String, _ApprovalState> _pendingApprovals = {};

  PromptToolStateValidator(this.context);

  void recordToolCall(
    ToolCallPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _requireNonEmpty(
      part.toolCallId,
      'toolCallId',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _requireNonEmpty(
      part.toolName,
      'toolName',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    if (_pendingClientToolCalls.containsKey(part.toolCallId)) {
      _fail(
        messageIndex,
        partIndex,
        'tool call "${part.toolCallId}" is already waiting for a tool result.',
      );
    }

    final state = _ToolCallState(
      toolCallId: part.toolCallId,
      toolName: part.toolName,
      providerExecuted: part.providerExecuted,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _seenToolCalls[part.toolCallId] = state;

    if (!part.providerExecuted) {
      _pendingClientToolCalls[part.toolCallId] = state;
    }
  }

  void recordApprovalRequest(
    ToolApprovalRequestPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _requireNonEmpty(
      part.approvalId,
      'approvalId',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _requireNonEmpty(
      part.toolCallId,
      'toolCallId',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final toolCall = _seenToolCalls[part.toolCallId];
    if (toolCall == null) {
      _fail(
        messageIndex,
        partIndex,
        'approval request "${part.approvalId}" references missing tool call '
        '"${part.toolCallId}".',
      );
    }

    if (!toolCall.providerExecuted) {
      _fail(
        messageIndex,
        partIndex,
        'approval request "${part.approvalId}" references client-executed '
        'tool call "${part.toolCallId}".',
      );
    }

    if (_pendingApprovals.containsKey(part.approvalId)) {
      _fail(
        messageIndex,
        partIndex,
        'approval request "${part.approvalId}" is already waiting for a '
        'response.',
      );
    }

    _pendingApprovals[part.approvalId] = _ApprovalState(
      approvalId: part.approvalId,
      toolCallId: part.toolCallId,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void validateAssistantToolResult(
    ToolResultPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _requireNonEmpty(
      part.toolCallId,
      'toolCallId',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _requireNonEmpty(
      part.toolName,
      'toolName',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final toolCall = _seenToolCalls[part.toolCallId];
    if (toolCall == null || !toolCall.providerExecuted) {
      _fail(
        messageIndex,
        partIndex,
        'assistant tool results are only valid for provider-executed tool '
        'calls. Client tool results must be placed in a tool message.',
      );
    }

    _requireToolNameMatch(
      expected: toolCall.toolName,
      actual: part.toolName,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void consumeToolResult(
    ToolResultPromptPart part, {
    required String messageToolName,
    required int messageIndex,
    required int partIndex,
  }) {
    _requireNonEmpty(
      part.toolCallId,
      'toolCallId',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _requireNonEmpty(
      part.toolName,
      'toolName',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _requireToolNameMatch(
      expected: messageToolName,
      actual: part.toolName,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final pending = _pendingClientToolCalls.remove(part.toolCallId);
    if (pending != null) {
      _requireToolNameMatch(
        expected: pending.toolName,
        actual: part.toolName,
        messageIndex: messageIndex,
        partIndex: partIndex,
      );
      return;
    }

    final toolCall = _seenToolCalls[part.toolCallId];
    if (toolCall != null && toolCall.providerExecuted) {
      _requireToolNameMatch(
        expected: toolCall.toolName,
        actual: part.toolName,
        messageIndex: messageIndex,
        partIndex: partIndex,
      );
      return;
    }

    _fail(
      messageIndex,
      partIndex,
      'tool result "${part.toolCallId}" has no matching assistant tool call.',
    );
  }

  void consumeApprovalResponse(
    ToolApprovalResponsePromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _requireNonEmpty(
      part.approvalId,
      'approvalId',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _requireNonEmpty(
      part.toolCallId,
      'toolCallId',
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final pending = _pendingApprovals.remove(part.approvalId);
    if (pending == null) {
      _fail(
        messageIndex,
        partIndex,
        'approval response "${part.approvalId}" has no matching assistant '
        'approval request.',
      );
    }

    if (pending.toolCallId != part.toolCallId) {
      _fail(
        messageIndex,
        partIndex,
        'approval response "${part.approvalId}" references tool call '
        '"${part.toolCallId}" but the request referenced '
        '"${pending.toolCallId}".',
      );
    }
  }

  void requireNoPendingBeforeNextConversationMessage(
    int messageIndex,
    String nextMessageName,
  ) {
    if (_pendingClientToolCalls.isNotEmpty) {
      final pending = _pendingClientToolCalls.values.first;
      _fail(
        messageIndex,
        null,
        '$nextMessageName cannot appear before a tool message returns a '
        'result for client tool call "${pending.toolCallId}".',
      );
    }

    if (_pendingApprovals.isNotEmpty) {
      final pending = _pendingApprovals.values.first;
      _fail(
        messageIndex,
        null,
        '$nextMessageName cannot appear before a tool message responds to '
        'approval request "${pending.approvalId}".',
      );
    }
  }

  void requireNoPendingAtEnd() {
    if (_pendingClientToolCalls.isNotEmpty) {
      final pending = _pendingClientToolCalls.values.first;
      _fail(
        pending.messageIndex,
        pending.partIndex,
        'client tool call "${pending.toolCallId}" is missing a tool result.',
      );
    }

    if (_pendingApprovals.isNotEmpty) {
      final pending = _pendingApprovals.values.first;
      _fail(
        pending.messageIndex,
        pending.partIndex,
        'approval request "${pending.approvalId}" is missing an approval '
        'response.',
      );
    }
  }

  void _requireNonEmpty(
    String value,
    String fieldName, {
    required int messageIndex,
    required int partIndex,
  }) {
    if (value.isNotEmpty) {
      return;
    }

    _fail(
      messageIndex,
      partIndex,
      '$fieldName must not be empty.',
    );
  }

  void _requireToolNameMatch({
    required String expected,
    required String actual,
    required int messageIndex,
    required int partIndex,
  }) {
    if (expected == actual) {
      return;
    }

    _fail(
      messageIndex,
      partIndex,
      'tool name "$actual" does not match expected tool "$expected".',
    );
  }

  Never _fail(
    int messageIndex,
    int? partIndex,
    String message,
  ) {
    final path = partIndex == null
        ? '$context[$messageIndex]'
        : '$context[$messageIndex].parts[$partIndex]';
    throw ArgumentError('$path is invalid: $message');
  }
}

final class _ToolCallState {
  final String toolCallId;
  final String toolName;
  final bool providerExecuted;
  final int messageIndex;
  final int partIndex;

  const _ToolCallState({
    required this.toolCallId,
    required this.toolName,
    required this.providerExecuted,
    required this.messageIndex,
    required this.partIndex,
  });
}

final class _ApprovalState {
  final String approvalId;
  final String toolCallId;
  final int messageIndex;
  final int partIndex;

  const _ApprovalState({
    required this.approvalId,
    required this.toolCallId,
    required this.messageIndex,
    required this.partIndex,
  });
}
