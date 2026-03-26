import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';

final class ToolOutputUpdate {
  final String toolCallId;
  final String toolName;
  final Object? output;
  final bool isError;
  final ChatRequestOptions options;

  const ToolOutputUpdate({
    required this.toolCallId,
    required this.toolName,
    this.output,
    this.isError = false,
    this.options = const ChatRequestOptions(),
  });
}

final class ToolApprovalResponse {
  final String approvalId;
  final bool approved;
  final ChatRequestOptions options;

  const ToolApprovalResponse({
    required this.approvalId,
    required this.approved,
    this.options = const ChatRequestOptions(),
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

  ChatSessionSnapshot exportSnapshot();

  Future<void> dispose();
}
