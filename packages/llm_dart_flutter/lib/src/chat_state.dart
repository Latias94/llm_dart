import 'package:llm_dart_core/llm_dart_core.dart';

enum ChatStatus {
  ready,
  submitting,
  streaming,
  error,
}

final class ChatState {
  final String chatId;
  final List<ChatUiMessage> messages;
  final ChatStatus status;
  final Object? error;

  ChatState({
    required this.chatId,
    required List<ChatUiMessage> messages,
    this.status = ChatStatus.ready,
    this.error,
  }) : messages = List.unmodifiable(messages);

  ChatState copyWith({
    String? chatId,
    List<ChatUiMessage>? messages,
    ChatStatus? status,
    Object? error = _sentinel,
  }) {
    return ChatState(
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      error: identical(error, _sentinel) ? this.error : error,
    );
  }
}

const Object _sentinel = Object();
