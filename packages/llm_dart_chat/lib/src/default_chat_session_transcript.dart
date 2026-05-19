import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_input.dart';
import 'chat_session.dart';
import 'chat_session_message_support.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';

final class DefaultChatSessionUserAppend {
  final ChatUiMessage uiMessage;

  const DefaultChatSessionUserAppend({
    required this.uiMessage,
  });
}

final class DefaultChatSessionDetachedAssistant {
  final List<ChatUiMessage> messages;
  final ChatUiMessage? assistantMessage;

  const DefaultChatSessionDetachedAssistant({
    required this.messages,
    required this.assistantMessage,
  });
}

final class DefaultChatSessionTranscript {
  final List<PromptMessage> _promptHistory = [];

  DefaultChatSessionTranscript(Iterable<PromptMessage> initialPrompt) {
    _promptHistory.addAll(initialPrompt);
  }

  List<PromptMessage> get prompt => List<PromptMessage>.of(_promptHistory);

  DefaultChatSessionUserAppend appendUserInput(
    ChatInput input, {
    required String messageId,
  }) {
    final promptMessages = normalizeModelMessages([input.message]);
    final promptMessage = promptMessages.single;
    _promptHistory.add(promptMessage);

    return DefaultChatSessionUserAppend(
      uiMessage: promptMessageToChatUiMessage(
        promptMessage,
        id: messageId,
      ),
    );
  }

  void removeTrailingAssistantPrompt() {
    if (_promptHistory.isNotEmpty &&
        _promptHistory.last is AssistantPromptMessage) {
      _promptHistory.removeLast();
    }
  }

  void appendAssistantPromptIfPresent(
    ChatUiMessage assistantMessage, {
    int startPartIndex = 0,
  }) {
    final promptMessages = assistantPromptMessagesFromChatUiMessage(
      assistantMessage,
      startPartIndex: startPartIndex,
    );
    if (promptMessages.isNotEmpty) {
      _promptHistory.addAll(promptMessages);
    }
  }

  void appendToolOutput(ToolOutputUpdate update) {
    _promptHistory.add(
      ToolPromptMessage(
        toolName: update.toolName,
        parts: [
          ToolResultPromptPart(
            toolCallId: update.toolCallId,
            toolName: update.toolName,
            toolOutput: update.toolOutput,
          ),
        ],
      ),
    );
  }

  void appendToolApprovalResponse({
    required ToolApprovalResponse response,
    required ToolUiPart pendingTool,
  }) {
    _promptHistory.add(
      ToolPromptMessage(
        toolName: pendingTool.toolName,
        parts: [
          ToolApprovalResponsePromptPart(
            approvalId: response.approvalId,
            toolCallId: pendingTool.toolCallId,
            approved: response.approved,
            reason: response.reason,
          ),
        ],
      ),
    );
  }

  ChatSessionSnapshot snapshot(ChatState state) {
    return ChatSessionSnapshot(
      chatId: state.chatId,
      prompt: prompt,
      messages: List<ChatUiMessage>.of(state.messages),
      status: state.status,
      error: state.error,
    );
  }

  List<ChatUiMessage> removeTrailingAssistantMessage(
    List<ChatUiMessage> messages,
  ) {
    final currentMessages = List<ChatUiMessage>.of(messages);
    if (currentMessages.isNotEmpty &&
        currentMessages.last.role == ChatUiRole.assistant) {
      currentMessages.removeLast();
    }
    return currentMessages;
  }

  DefaultChatSessionDetachedAssistant detachTrailingAssistantMessage(
    List<ChatUiMessage> messages,
  ) {
    final currentMessages = List<ChatUiMessage>.of(messages);
    ChatUiMessage? previousAssistantMessage;
    if (currentMessages.isNotEmpty &&
        currentMessages.last.role == ChatUiRole.assistant) {
      previousAssistantMessage = currentMessages.removeLast();
    }

    return DefaultChatSessionDetachedAssistant(
      messages: currentMessages,
      assistantMessage: previousAssistantMessage,
    );
  }

  ChatUiMessage requireLatestAssistantMessage(List<ChatUiMessage> messages) {
    if (messages.isEmpty || messages.last.role != ChatUiRole.assistant) {
      throw StateError('No assistant message is available for tool handling.');
    }

    return messages.last;
  }

  List<ChatUiMessage> replaceLatestAssistantMessage(
    List<ChatUiMessage> messages,
    ChatUiMessage assistantMessage,
  ) {
    final updatedMessages = List<ChatUiMessage>.of(messages);
    if (updatedMessages.isEmpty ||
        updatedMessages.last.role != ChatUiRole.assistant) {
      throw StateError('No assistant message is available for replacement.');
    }

    updatedMessages[updatedMessages.length - 1] = assistantMessage;
    return updatedMessages;
  }

  List<ChatUiMessage> upsertAssistantMessage(
    List<ChatUiMessage> messages,
    ChatUiMessage assistantMessage,
  ) {
    final updatedMessages = List<ChatUiMessage>.of(messages);
    if (updatedMessages.isNotEmpty &&
        updatedMessages.last.role == ChatUiRole.assistant) {
      updatedMessages[updatedMessages.length - 1] = assistantMessage;
    } else {
      updatedMessages.add(assistantMessage);
    }
    return updatedMessages;
  }
}
