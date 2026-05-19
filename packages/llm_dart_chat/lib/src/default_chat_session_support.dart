import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show transportErrorToModelError;

import 'chat_session.dart';
import 'chat_state.dart';
import 'tool_execution_registry.dart';

typedef MessageIdGenerator = String Function();

ChatStatus normalizeRestoredChatStatus(ChatStatus status) {
  return switch (status) {
    ChatStatus.submitting || ChatStatus.streaming => ChatStatus.ready,
    _ => status,
  };
}

ModelError? normalizeRestoredChatError(
  ChatStatus status,
  ModelError? error,
) {
  return normalizeRestoredChatStatus(status) == ChatStatus.error ? error : null;
}

ModelError chatSessionErrorToModelError(Object error) {
  return switch (error) {
    ChatUiStreamError() => error.toModelError(),
    _ => transportErrorToModelError(error),
  };
}

MessageIdGenerator sequentialChatMessageId({
  Iterable<String> existingIds = const [],
}) {
  final reservedIds = existingIds.toSet();
  var index = 0;

  return () {
    while (true) {
      final value = 'msg-$index';
      index += 1;
      if (reservedIds.add(value)) {
        return value;
      }
    }
  };
}

ChatOnToolCall? resolveChatToolExecutionCallback({
  ChatOnToolCall? onToolCall,
  ToolExecutionRegistry? toolExecutionRegistry,
}) {
  if (onToolCall != null && toolExecutionRegistry != null) {
    throw ArgumentError(
      'Provide either onToolCall or toolExecutionRegistry, not both.',
    );
  }

  return onToolCall ?? toolExecutionRegistry?.call;
}
