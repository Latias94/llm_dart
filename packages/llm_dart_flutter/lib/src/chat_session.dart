import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_state.dart';

final class ToolOutputUpdate {
  final String toolCallId;
  final String toolName;
  final Object? output;
  final bool isError;

  const ToolOutputUpdate({
    required this.toolCallId,
    required this.toolName,
    this.output,
    this.isError = false,
  });
}

final class ToolApprovalResponse {
  final String approvalId;
  final bool approved;

  const ToolApprovalResponse({
    required this.approvalId,
    required this.approved,
  });
}

abstract interface class ChatSession {
  ChatState get state;

  Stream<ChatState> get states;

  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  });

  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  });

  Future<void> addToolOutput(ToolOutputUpdate update);

  Future<void> respondToolApproval(ToolApprovalResponse response);

  Future<void> resume();

  Future<void> stop();

  Future<void> clearError();

  Future<void> dispose();
}
