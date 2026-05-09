import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session_message_support.dart';
import 'chat_session.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';
import 'chat_session_tool_support.dart';
import 'chat_transport.dart';
import 'chat_ui_stream_reader.dart';
import 'tool_execution_registry.dart';

typedef MessageIdGenerator = String Function();

final class DefaultChatSession implements ChatSession {
  final ChatTransport transport;
  final ChatOnToolCall? onToolCall;
  final StreamController<ChatState> _statesController;
  final StreamController<DataUiPart<Object?>> _transientDataPartsController;
  final List<PromptMessage> _promptHistory = [];
  final MessageIdGenerator _messageIdGenerator;
  final Set<String> _scheduledToolExecutionKeys = <String>{};

  ChatState _state;
  StreamSubscription<ChatUiStreamChunk>? _activeSubscription;
  ChatUiStreamReader? _activeStreamReader;
  Completer<void>? _activeCompletion;
  int _activePromptAppendStartIndex = 0;
  bool _isDisposed = false;

  DefaultChatSession({
    required ChatTransport transport,
    String? chatId,
    List<PromptMessage> initialPrompt = const [],
    MessageIdGenerator? messageIdGenerator,
    ChatOnToolCall? onToolCall,
    ToolExecutionRegistry? toolExecutionRegistry,
  }) : this._(
          transport: transport,
          onToolCall: _resolveToolExecutionCallback(
            onToolCall: onToolCall,
            toolExecutionRegistry: toolExecutionRegistry,
          ),
          initialState: ChatState(
            chatId: chatId ?? 'chat-${DateTime.now().microsecondsSinceEpoch}',
            messages: visibleMessagesFromPrompt(initialPrompt),
          ),
          initialPrompt: initialPrompt,
          messageIdGenerator: messageIdGenerator,
        );

  DefaultChatSession.fromSnapshot({
    required ChatTransport transport,
    required ChatSessionSnapshot snapshot,
    MessageIdGenerator? messageIdGenerator,
    ChatOnToolCall? onToolCall,
    ToolExecutionRegistry? toolExecutionRegistry,
  }) : this._(
          transport: transport,
          onToolCall: _resolveToolExecutionCallback(
            onToolCall: onToolCall,
            toolExecutionRegistry: toolExecutionRegistry,
          ),
          initialState: ChatState(
            chatId: snapshot.chatId,
            messages: snapshot.messages,
            status: _normalizeRestoredStatus(snapshot.status),
            error: _normalizeRestoredError(snapshot.status, snapshot.error),
          ),
          initialPrompt: snapshot.prompt,
          messageIdGenerator: messageIdGenerator,
        );

  DefaultChatSession._({
    required this.transport,
    required this.onToolCall,
    required ChatState initialState,
    required List<PromptMessage> initialPrompt,
    MessageIdGenerator? messageIdGenerator,
  })  : _statesController = StreamController<ChatState>.broadcast(sync: true),
        _transientDataPartsController =
            StreamController<DataUiPart<Object?>>.broadcast(sync: true),
        _messageIdGenerator = messageIdGenerator ??
            _sequentialMessageId(
              existingIds: initialState.messages.map((message) => message.id),
            ),
        _state = initialState {
    _promptHistory.addAll(initialPrompt);
    _maybeScheduleAutomaticToolExecution();
  }

  @override
  ChatState get state => _state;

  @override
  Stream<ChatState> get states => _statesController.stream;

  @override
  Stream<DataUiPart<Object?>> get transientDataParts =>
      _transientDataPartsController.stream;

  @override
  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    _ensureUsable();
    _ensureIdle('sendMessage');

    final userMessage = promptMessageToChatUiMessage(
      input.message,
      id: _messageIdGenerator(),
    );
    _promptHistory.add(input.message);
    _emitState(
      _state.copyWith(
        messages: [..._state.messages, userMessage],
        status: ChatStatus.submitting,
        error: null,
      ),
    );

    await _runAssistantTurn(
      options: options,
      trigger: ChatTransportTrigger.sendMessage,
    );
  }

  @override
  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    _ensureUsable();
    _ensureIdle('regenerate');

    if (messageId != null &&
        (_state.messages.isEmpty || _state.messages.last.id != messageId)) {
      throw UnsupportedError(
        'Regenerating a non-latest message has not been implemented yet.',
      );
    }

    if (_promptHistory.isNotEmpty &&
        _promptHistory.last is AssistantPromptMessage) {
      _promptHistory.removeLast();
    }

    final currentMessages = List<ChatUiMessage>.of(_state.messages);
    if (currentMessages.isNotEmpty &&
        currentMessages.last.role == ChatUiRole.assistant) {
      currentMessages.removeLast();
    }

    _emitState(
      _state.copyWith(
        messages: currentMessages,
        status: ChatStatus.submitting,
        error: null,
      ),
    );

    await _runAssistantTurn(
      options: options,
      trigger: ChatTransportTrigger.regenerate,
    );
  }

  @override
  Future<void> addToolOutput(ToolOutputUpdate update) {
    _ensureUsable();
    _ensureIdle('addToolOutput');

    final toolOutput = update.toolOutput;
    final assistantMessage = _requireLatestAssistantMessage();
    final updatedAssistantMessage = chatUpdateToolPartByCallId(
      assistantMessage,
      update.toolCallId,
      (part) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        state: _toolOutputState(toolOutput),
        input: part.input,
        inputText: part.inputText,
        output: update.output,
        toolOutput: toolOutput,
        errorText:
            toolOutput.isError ? _stringifyToolOutputValue(toolOutput) : null,
        providerExecuted: part.providerExecuted,
        isDynamic: part.isDynamic,
        preliminary: false,
        title: part.title,
        approval: part.approval,
        callProviderMetadata: part.callProviderMetadata,
        resultProviderMetadata: part.resultProviderMetadata,
      ),
      requirePendingState: true,
    );

    _promptHistory.add(
      ToolPromptMessage(
        toolName: update.toolName,
        parts: [
          ToolResultPromptPart(
            toolCallId: update.toolCallId,
            toolName: update.toolName,
            toolOutput: toolOutput,
          ),
        ],
      ),
    );

    final nextStatus = chatDeriveCompletionStatus(updatedAssistantMessage);
    _emitState(
      _state.copyWith(
        messages: _replaceLatestAssistantMessage(updatedAssistantMessage),
        status:
            nextStatus == ChatStatus.ready ? ChatStatus.submitting : nextStatus,
        error: null,
      ),
    );

    if (nextStatus != ChatStatus.ready) {
      _maybeScheduleAutomaticToolExecution();
      return Future.value();
    }

    return _runAssistantTurn(
      options: update.options,
      trigger: ChatTransportTrigger.toolOutput,
      seedAssistantMessage: updatedAssistantMessage,
    );
  }

  @override
  Future<void> addDataPart<T>(DataUiPart<T> part) async {
    _ensureUsable();

    final streamReader = _activeStreamReader;
    if (streamReader != null) {
      _upsertAssistantMessage(streamReader.applyDataPart(part));
      return;
    }

    if (_state.status != ChatStatus.awaitingTool &&
        _state.status != ChatStatus.awaitingApproval) {
      throw StateError(
        'Cannot call addDataPart unless the current assistant turn is active or waiting for tool or approval input.',
      );
    }

    final assistantMessage = _requireLatestAssistantMessage();
    final updatedAssistantMessage = ChatUiAccumulator(
      messageId: assistantMessage.id,
      seedMessage: assistantMessage,
    ).applyDataPart(part);

    _emitState(
      _state.copyWith(
        messages: _replaceLatestAssistantMessage(updatedAssistantMessage),
        error: null,
      ),
    );
  }

  @override
  Future<void> respondToolApproval(ToolApprovalResponse response) async {
    _ensureUsable();
    _ensureIdle('respondToolApproval');

    final assistantMessage = _requireLatestAssistantMessage();
    final pendingTool = chatRequirePendingApprovalToolPart(
      assistantMessage,
      response.approvalId,
    );
    final updatedAssistantMessage = chatUpdateToolPartByApprovalId(
      assistantMessage,
      response.approvalId,
      (part) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        state: response.approved
            ? ToolUiPartState.approvalResponded
            : ToolUiPartState.outputDenied,
        input: part.input,
        inputText: part.inputText,
        output: part.output,
        toolOutput: part.toolOutput,
        errorText: part.errorText,
        providerExecuted: part.providerExecuted,
        isDynamic: part.isDynamic,
        preliminary: part.preliminary,
        title: part.title,
        approval: ToolApprovalUiState(
          approvalId: response.approvalId,
          approved: response.approved,
          reason: response.reason,
        ),
        callProviderMetadata: part.callProviderMetadata,
        resultProviderMetadata: part.resultProviderMetadata,
      ),
    );

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

    final nextStatus = chatDeriveCompletionStatus(updatedAssistantMessage);
    final shouldContinueProviderTurn = nextStatus == ChatStatus.ready &&
        chatHasApprovedProviderExecutedTool(updatedAssistantMessage);

    if (shouldContinueProviderTurn) {
      _emitState(
        _state.copyWith(
          messages: _replaceLatestAssistantMessage(updatedAssistantMessage),
          status: ChatStatus.submitting,
          error: null,
        ),
      );

      return _runAssistantTurn(
        options: response.options,
        trigger: ChatTransportTrigger.toolApproval,
        seedAssistantMessage: updatedAssistantMessage,
      );
    }

    _emitState(
      _state.copyWith(
        messages: _replaceLatestAssistantMessage(updatedAssistantMessage),
        status: nextStatus,
        error: null,
      ),
    );
    _maybeScheduleAutomaticToolExecution();
  }

  @override
  Future<void> resume() async {
    _ensureUsable();
    _ensureIdle('resume');

    if (_state.status != ChatStatus.error) {
      throw StateError(
        'Cannot call resume unless the chat session is in the error state.',
      );
    }

    final stream = transport.reconnect(_state.chatId);
    if (stream == null) {
      throw StateError(
        'The configured chat transport does not have reconnect state for chat "${_state.chatId}".',
      );
    }

    final messages = List<ChatUiMessage>.of(_state.messages);
    ChatUiMessage? previousAssistantMessage;
    if (messages.isNotEmpty && messages.last.role == ChatUiRole.assistant) {
      previousAssistantMessage = messages.removeLast();
    }

    _emitState(
      _state.copyWith(
        messages: messages,
        status: ChatStatus.streaming,
        error: null,
      ),
    );

    await _consumeAssistantStream(
      stream: stream,
      assistantMessageId: previousAssistantMessage?.id ?? _messageIdGenerator(),
      promptAppendStartIndex: 0,
    );
  }

  @override
  Future<void> stop() async {
    _ensureUsable();

    final subscription = _activeSubscription;
    if (subscription == null) {
      return;
    }

    final streamReader = _activeStreamReader;
    if (streamReader != null) {
      final abortedMessage = streamReader.applyEvent(
        const AbortEvent(),
      );
      _upsertAssistantMessage(abortedMessage);
      final assistantMessage = streamReader.applyEvent(
        const FinishEvent(
          finishReason: FinishReason.aborted,
        ),
      );
      _upsertAssistantMessage(assistantMessage);
      _appendAssistantPromptIfPresent(
        assistantMessage,
        startPartIndex: _activePromptAppendStartIndex,
      );
    }

    await subscription.cancel();
    final completion = _activeCompletion;
    _clearActiveTurn();
    _emitState(
      _state.copyWith(
        status: ChatStatus.ready,
        error: null,
      ),
    );
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  @override
  Future<void> clearError() async {
    _ensureUsable();
    _emitState(
      _state.copyWith(
        status: ChatStatus.ready,
        error: null,
      ),
    );
  }

  @override
  ChatSessionSnapshot exportSnapshot() {
    _ensureUsable();
    if (_activeSubscription != null) {
      throw StateError(
        'Cannot export a chat snapshot while an assistant turn is still active.',
      );
    }

    return ChatSessionSnapshot(
      chatId: _state.chatId,
      prompt: List<PromptMessage>.of(_promptHistory),
      messages: List<ChatUiMessage>.of(_state.messages),
      status: _state.status,
      error: _state.error,
    );
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    await _activeSubscription?.cancel();
    final completion = _activeCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    _clearActiveTurn();
    _isDisposed = true;
    if (!_transientDataPartsController.isClosed) {
      await _transientDataPartsController.close();
    }
    await _statesController.close();
  }

  Future<void> _runAssistantTurn({
    required ChatRequestOptions options,
    required ChatTransportTrigger trigger,
    ChatUiMessage? seedAssistantMessage,
  }) async {
    _emitState(
      _state.copyWith(
        status: ChatStatus.streaming,
        error: null,
      ),
    );

    final stream = transport.sendMessages(
      ChatTransportRequest(
        chatId: _state.chatId,
        trigger: trigger,
        prompt: List<PromptMessage>.of(_promptHistory),
        options: options,
      ),
    );

    await _consumeAssistantStream(
      stream: stream,
      assistantMessageId: seedAssistantMessage?.id ?? _messageIdGenerator(),
      seedAssistantMessage: seedAssistantMessage,
      promptAppendStartIndex: seedAssistantMessage?.parts.length ?? 0,
      syntheticStepStartOnSeed: true,
    );
  }

  Future<void> _consumeAssistantStream({
    required Stream<ChatUiStreamChunk> stream,
    required String assistantMessageId,
    required int promptAppendStartIndex,
    ChatUiMessage? seedAssistantMessage,
    bool syntheticStepStartOnSeed = true,
  }) async {
    final streamReader = ChatUiStreamReader(
      messageId: assistantMessageId,
      seedMessage: seedAssistantMessage,
    );
    final completion = Completer<void>();
    var completed = false;
    ChatUiMessage? latestAssistantMessage;

    _activeStreamReader = streamReader;
    _activeCompletion = completion;
    _activePromptAppendStartIndex = promptAppendStartIndex;

    if (seedAssistantMessage != null && syntheticStepStartOnSeed) {
      latestAssistantMessage = streamReader.applyEvent(
        const StepStartEvent(),
      );
      _upsertAssistantMessage(latestAssistantMessage);
    }

    _activeSubscription = stream.listen(
      (chunk) async {
        final projectedMessage = streamReader.applyChunk(chunk);
        switch (chunk) {
          case ChatUiTransientDataPartChunk(:final part):
            _emitTransientDataPart(
              DataUiPart<Object?>(
                id: part.id,
                key: part.key,
                data: part.data,
              ),
            );
          case ChatUiEventChunk(:final event):
            latestAssistantMessage = projectedMessage;
            _upsertAssistantMessage(projectedMessage);

            if (event is ErrorEvent) {
              completed = true;
              streamReader.close();
              await _activeSubscription?.cancel();
              _clearActiveTurn();
              _emitState(
                _state.copyWith(
                  status: ChatStatus.error,
                  error: event.error,
                ),
              );
              if (!completion.isCompleted) {
                completion.complete();
              }
              return;
            }

            if (event is FinishEvent) {
              // Wait for the stream to close so trailing message-metadata or
              // message-finish chunks can still patch the final assistant
              // message before the session transitions out of the active turn.
            }
          case ChatUiDataPartChunk() ||
                ChatUiMessageStartChunk() ||
                ChatUiMessageMetadataChunk() ||
                ChatUiMessageFinishChunk():
            latestAssistantMessage = projectedMessage;
            _upsertAssistantMessage(projectedMessage);
        }
      },
      onError: (error, stackTrace) {
        if (_activeCompletion != completion) {
          return;
        }

        completed = true;
        streamReader.fail(error, stackTrace);
        _clearActiveTurn();
        _emitState(
          _state.copyWith(
            status: ChatStatus.error,
            error: transportErrorToModelError(error),
          ),
        );
        if (!completion.isCompleted) {
          completion.complete();
        }
      },
      onDone: () {
        if (completed || _activeCompletion != completion) {
          return;
        }

        streamReader.close();

        if (latestAssistantMessage != null) {
          _appendAssistantPromptIfPresent(
            latestAssistantMessage!,
            startPartIndex: promptAppendStartIndex,
          );
        }

        _clearActiveTurn();
        _emitState(
          _state.copyWith(
            status: chatDeriveCompletionStatus(latestAssistantMessage),
            error: null,
          ),
        );
        _maybeScheduleAutomaticToolExecution();
        if (!completion.isCompleted) {
          completion.complete();
        }
      },
      cancelOnError: false,
    );

    await completion.future;
  }

  void _appendAssistantPromptIfPresent(
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

  void _upsertAssistantMessage(ChatUiMessage assistantMessage) {
    final messages = List<ChatUiMessage>.of(_state.messages);
    if (messages.isNotEmpty && messages.last.role == ChatUiRole.assistant) {
      messages[messages.length - 1] = assistantMessage;
    } else {
      messages.add(assistantMessage);
    }

    _emitState(
      _state.copyWith(
        messages: messages,
        error: null,
      ),
    );
  }

  void _emitState(ChatState state) {
    _state = state;
    if (!_isDisposed && !_statesController.isClosed) {
      _statesController.add(state);
    }
  }

  void _emitTransientDataPart(DataUiPart<Object?> part) {
    if (!_isDisposed && !_transientDataPartsController.isClosed) {
      _transientDataPartsController.add(part);
    }
  }

  void _clearActiveTurn() {
    _activeSubscription = null;
    _activeStreamReader = null;
    _activeCompletion = null;
    _activePromptAppendStartIndex = 0;
  }

  void _maybeScheduleAutomaticToolExecution() {
    final handler = onToolCall;
    if (handler == null ||
        _isDisposed ||
        _activeSubscription != null ||
        _state.status != ChatStatus.awaitingTool) {
      return;
    }

    final assistantMessage = _latestAssistantMessageOrNull();
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
        chatId: _state.chatId,
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

    if (result == null || !_canApplyAutomaticToolOutput(request.toolCallId)) {
      return;
    }

    try {
      await addToolOutput(
        ToolOutputUpdate(
          toolCallId: request.toolCallId,
          toolName: request.toolName,
          toolOutput: result.toolOutput,
          options: result.options,
        ),
      );
    } on StateError {
      if (_canApplyAutomaticToolOutput(request.toolCallId)) {
        rethrow;
      }
    }
  }

  bool _canApplyAutomaticToolOutput(String toolCallId) {
    if (_isDisposed ||
        _activeSubscription != null ||
        _state.status != ChatStatus.awaitingTool) {
      return false;
    }

    final assistantMessage = _latestAssistantMessageOrNull();
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

  void _ensureUsable() {
    if (_isDisposed) {
      throw StateError('This chat session has already been disposed.');
    }
  }

  ChatUiMessage? _latestAssistantMessageOrNull() {
    if (_state.messages.isEmpty ||
        _state.messages.last.role != ChatUiRole.assistant) {
      return null;
    }

    return _state.messages.last;
  }

  void _ensureIdle(String operation) {
    if (_activeSubscription != null) {
      throw StateError(
        'Cannot call $operation while another assistant turn is still active.',
      );
    }
  }

  ChatUiMessage _requireLatestAssistantMessage() {
    if (_state.messages.isEmpty ||
        _state.messages.last.role != ChatUiRole.assistant) {
      throw StateError('No assistant message is available for tool handling.');
    }

    return _state.messages.last;
  }

  List<ChatUiMessage> _replaceLatestAssistantMessage(
    ChatUiMessage assistantMessage,
  ) {
    final messages = List<ChatUiMessage>.of(_state.messages);
    if (messages.isEmpty || messages.last.role != ChatUiRole.assistant) {
      throw StateError('No assistant message is available for replacement.');
    }

    messages[messages.length - 1] = assistantMessage;
    return messages;
  }
}

ChatStatus _normalizeRestoredStatus(ChatStatus status) {
  return switch (status) {
    ChatStatus.submitting || ChatStatus.streaming => ChatStatus.ready,
    _ => status,
  };
}

ModelError? _normalizeRestoredError(ChatStatus status, ModelError? error) {
  return _normalizeRestoredStatus(status) == ChatStatus.error ? error : null;
}

MessageIdGenerator _sequentialMessageId({
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

String _toolExecutionKey(String messageId, String toolCallId) {
  return '$messageId\u0000$toolCallId';
}

ToolUiPartState _toolOutputState(ToolOutput output) {
  if (output.denied) {
    return ToolUiPartState.outputDenied;
  }

  return output.isError
      ? ToolUiPartState.outputError
      : ToolUiPartState.outputAvailable;
}

String _stringifyToolOutputValue(ToolOutput output) {
  final value = output.value;
  if (value is String) {
    return value;
  }

  try {
    return jsonEncode(value);
  } catch (_) {
    return '$value';
  }
}

ChatOnToolCall? _resolveToolExecutionCallback({
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
