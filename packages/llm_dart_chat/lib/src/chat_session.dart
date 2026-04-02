import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

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
  final String? reason;
  final ChatRequestOptions options;

  const ToolApprovalResponse({
    required this.approvalId,
    required this.approved,
    this.reason,
    this.options = const ChatRequestOptions(),
  });
}

final class ToolExecutionRequest {
  final String chatId;
  final String messageId;
  final String toolCallId;
  final String toolName;
  final Object? input;
  final String? inputText;
  final bool isDynamic;
  final String? title;
  final ToolApprovalUiState? approval;
  final ProviderMetadata? callProviderMetadata;

  const ToolExecutionRequest({
    required this.chatId,
    required this.messageId,
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.inputText,
    this.isDynamic = false,
    this.title,
    this.approval,
    this.callProviderMetadata,
  });

  Map<String, Object?> requireJsonObjectInput() {
    final normalized = switch (input) {
      null => null,
      Map<String, Object?>() => input as Map<String, Object?>,
      Map() => _normalizeAnonymousJsonObject(input as Map),
      _ => null,
    };

    if (normalized != null) {
      return normalized;
    }

    throw ToolInputDecodeException(
      'Tool "$toolName" expected a JSON object input.',
      toolName: toolName,
      toolCallId: toolCallId,
      input: input,
    );
  }

  T decodeJsonObjectInput<T>(
    T Function(Map<String, Object?> json) decode,
  ) {
    final json = requireJsonObjectInput();

    try {
      return decode(json);
    } on ToolInputDecodeException {
      rethrow;
    } catch (error) {
      throw ToolInputDecodeException(
        'Failed to decode tool "$toolName" input: $error',
        toolName: toolName,
        toolCallId: toolCallId,
        input: json,
        cause: error,
      );
    }
  }

  Map<String, Object?> _normalizeAnonymousJsonObject(Map value) {
    final normalized = <String, Object?>{};

    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ToolInputDecodeException(
          'Tool "$toolName" input object keys must be strings.',
          toolName: toolName,
          toolCallId: toolCallId,
          input: value,
        );
      }

      normalized[key] = entry.value;
    }

    return normalized;
  }
}

final class ToolExecutionResult {
  final Object? output;
  final bool isError;
  final ChatRequestOptions options;

  const ToolExecutionResult.output(
    this.output, {
    this.options = const ChatRequestOptions(),
  }) : isError = false;

  const ToolExecutionResult.error(
    this.output, {
    this.options = const ChatRequestOptions(),
  }) : isError = true;
}

typedef ChatOnToolCall = FutureOr<ToolExecutionResult?> Function(
  ToolExecutionRequest request,
);

final class ToolInputDecodeException implements Exception {
  final String message;
  final String toolName;
  final String toolCallId;
  final Object? input;
  final Object? cause;

  const ToolInputDecodeException(
    this.message, {
    required this.toolName,
    required this.toolCallId,
    this.input,
    this.cause,
  });

  @override
  String toString() => 'ToolInputDecodeException: $message';
}

abstract interface class ChatSession {
  ChatState get state;

  Stream<ChatState> get states;

  Stream<DataUiPart<Object?>> get transientDataParts;

  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  });

  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  });

  Future<void> addToolOutput(ToolOutputUpdate update);

  Future<void> addDataPart<T>(DataUiPart<T> part);

  Future<void> respondToolApproval(ToolApprovalResponse response);

  Future<void> resume();

  Future<void> stop();

  Future<void> clearError();

  ChatSessionSnapshot exportSnapshot();

  Future<void> dispose();
}
