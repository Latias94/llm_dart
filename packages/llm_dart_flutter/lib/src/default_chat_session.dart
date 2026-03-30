import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';
import 'chat_transport.dart';

typedef MessageIdGenerator = String Function();

final class DefaultChatSession implements ChatSession {
  final ChatTransport transport;
  final StreamController<ChatState> _statesController;
  final List<PromptMessage> _promptHistory = [];
  final MessageIdGenerator _messageIdGenerator;

  ChatState _state;
  StreamSubscription<ChatTransportChunk>? _activeSubscription;
  ChatUiAccumulator? _activeAccumulator;
  Completer<void>? _activeCompletion;
  int _activePromptAppendStartIndex = 0;
  bool _isDisposed = false;

  DefaultChatSession({
    required ChatTransport transport,
    String? chatId,
    List<PromptMessage> initialPrompt = const [],
    MessageIdGenerator? messageIdGenerator,
  }) : this._(
          transport: transport,
          initialState: ChatState(
            chatId: chatId ?? 'chat-${DateTime.now().microsecondsSinceEpoch}',
            messages: _visibleMessagesFromPrompt(initialPrompt),
          ),
          initialPrompt: initialPrompt,
          messageIdGenerator: messageIdGenerator,
        );

  DefaultChatSession.fromSnapshot({
    required ChatTransport transport,
    required ChatSessionSnapshot snapshot,
    MessageIdGenerator? messageIdGenerator,
  }) : this._(
          transport: transport,
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
    required ChatState initialState,
    required List<PromptMessage> initialPrompt,
    MessageIdGenerator? messageIdGenerator,
  })  : _statesController = StreamController<ChatState>.broadcast(sync: true),
        _messageIdGenerator = messageIdGenerator ??
            _sequentialMessageId(
              existingIds: initialState.messages.map((message) => message.id),
            ),
        _state = initialState {
    _promptHistory.addAll(initialPrompt);
  }

  @override
  ChatState get state => _state;

  @override
  Stream<ChatState> get states => _statesController.stream;

  @override
  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    _ensureUsable();
    _ensureIdle('sendMessage');

    final userMessage = _promptMessageToUiMessage(
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

    await _runAssistantTurn(options: options);
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

    await _runAssistantTurn(options: options);
  }

  @override
  Future<void> addToolOutput(ToolOutputUpdate update) {
    _ensureUsable();
    _ensureIdle('addToolOutput');

    final assistantMessage = _requireLatestAssistantMessage();
    final updatedAssistantMessage = _updateToolPartByCallId(
      assistantMessage,
      update.toolCallId,
      (part) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        state: update.isError
            ? ToolUiPartState.outputError
            : ToolUiPartState.outputAvailable,
        input: part.input,
        inputText: part.inputText,
        output: update.output,
        errorText: update.isError ? '${update.output}' : null,
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
            output: update.output,
            isError: update.isError,
          ),
        ],
      ),
    );

    _emitState(
      _state.copyWith(
        messages: _replaceLatestAssistantMessage(updatedAssistantMessage),
        status: ChatStatus.submitting,
        error: null,
      ),
    );

    return _runAssistantTurn(
      options: update.options,
      seedAssistantMessage: updatedAssistantMessage,
    );
  }

  @override
  Future<void> addDataPart<T>(DataUiPart<T> part) async {
    _ensureUsable();

    final accumulator = _activeAccumulator;
    if (accumulator != null) {
      _upsertAssistantMessage(accumulator.applyDataPart(part));
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
    final pendingTool = _requirePendingApprovalToolPart(
      assistantMessage,
      response.approvalId,
    );
    final updatedAssistantMessage = _updateToolPartByApprovalId(
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

    if (response.approved && pendingTool.providerExecuted) {
      _emitState(
        _state.copyWith(
          messages: _replaceLatestAssistantMessage(updatedAssistantMessage),
          status: ChatStatus.submitting,
          error: null,
        ),
      );

      return _runAssistantTurn(
        options: response.options,
        seedAssistantMessage: updatedAssistantMessage,
      );
    }

    _emitState(
      _state.copyWith(
        messages: _replaceLatestAssistantMessage(updatedAssistantMessage),
        status: _deriveCompletionStatus(updatedAssistantMessage),
        error: null,
      ),
    );
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

    final accumulator = _activeAccumulator;
    if (accumulator != null) {
      final assistantMessage = accumulator.apply(
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
    await _statesController.close();
  }

  Future<void> _runAssistantTurn({
    required ChatRequestOptions options,
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
    required Stream<ChatTransportChunk> stream,
    required String assistantMessageId,
    required int promptAppendStartIndex,
    ChatUiMessage? seedAssistantMessage,
    bool syntheticStepStartOnSeed = true,
  }) async {
    final accumulator = ChatUiAccumulator(
      messageId: assistantMessageId,
      seedMessage: seedAssistantMessage,
    );
    final completion = Completer<void>();
    var completed = false;
    ChatUiMessage? latestAssistantMessage;

    _activeAccumulator = accumulator;
    _activeCompletion = completion;
    _activePromptAppendStartIndex = promptAppendStartIndex;

    if (seedAssistantMessage != null && syntheticStepStartOnSeed) {
      latestAssistantMessage = accumulator.apply(const StepStartEvent());
      _upsertAssistantMessage(latestAssistantMessage);
    }

    _activeSubscription = stream.listen(
      (chunk) async {
        switch (chunk) {
          case ChatTransportEventChunk(:final event):
            latestAssistantMessage = accumulator.apply(event);
            _upsertAssistantMessage(latestAssistantMessage!);

            if (event is ErrorEvent) {
              completed = true;
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
              completed = true;
              _appendAssistantPromptIfPresent(
                latestAssistantMessage!,
                startPartIndex: promptAppendStartIndex,
              );
              _clearActiveTurn();
              _emitState(
                _state.copyWith(
                  status: _deriveCompletionStatus(latestAssistantMessage),
                  error: null,
                ),
              );
              if (!completion.isCompleted) {
                completion.complete();
              }
            }
          case ChatTransportDataPartChunk(:final part):
            latestAssistantMessage = accumulator.applyDataPart(part);
            _upsertAssistantMessage(latestAssistantMessage!);
        }
      },
      onError: (error, stackTrace) {
        if (_activeCompletion != completion) {
          return;
        }

        completed = true;
        _clearActiveTurn();
        _emitState(
          _state.copyWith(
            status: ChatStatus.error,
            error: error,
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

        if (latestAssistantMessage != null) {
          _appendAssistantPromptIfPresent(
            latestAssistantMessage!,
            startPartIndex: promptAppendStartIndex,
          );
        }

        _clearActiveTurn();
        _emitState(
          _state.copyWith(
            status: _deriveCompletionStatus(latestAssistantMessage),
            error: null,
          ),
        );
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
    final promptMessages = _assistantPromptMessagesFromUi(
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

  void _clearActiveTurn() {
    _activeSubscription = null;
    _activeAccumulator = null;
    _activeCompletion = null;
    _activePromptAppendStartIndex = 0;
  }

  void _ensureUsable() {
    if (_isDisposed) {
      throw StateError('This chat session has already been disposed.');
    }
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

  ToolUiPart _requirePendingApprovalToolPart(
    ChatUiMessage message,
    String approvalId,
  ) {
    for (final part in message.parts) {
      if (part is! ToolUiPart || part.approval?.approvalId != approvalId) {
        continue;
      }

      if (part.state != ToolUiPartState.approvalRequested) {
        throw StateError(
          'Approval "$approvalId" is not waiting for a response.',
        );
      }

      return part;
    }

    throw StateError('No tool approval with ID "$approvalId" was found.');
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

  ChatStatus _deriveCompletionStatus(ChatUiMessage? assistantMessage) {
    if (assistantMessage == null) {
      return ChatStatus.ready;
    }

    final toolParts = assistantMessage.parts.whereType<ToolUiPart>().toList();
    if (toolParts
        .any((part) => part.state == ToolUiPartState.approvalRequested)) {
      return ChatStatus.awaitingApproval;
    }

    if (toolParts.any(
      (part) =>
          part.state == ToolUiPartState.inputAvailable ||
          part.state == ToolUiPartState.inputStreaming ||
          (!part.providerExecuted &&
              part.state == ToolUiPartState.approvalResponded),
    )) {
      return ChatStatus.awaitingTool;
    }

    return ChatStatus.ready;
  }

  ChatUiMessage _updateToolPartByCallId(
    ChatUiMessage message,
    String toolCallId,
    ToolUiPart Function(ToolUiPart part) transform, {
    bool requirePendingState = false,
  }) {
    var found = false;

    final parts = message.parts.map((part) {
      if (part is! ToolUiPart || part.toolCallId != toolCallId) {
        return part;
      }

      if (requirePendingState &&
          part.state != ToolUiPartState.inputAvailable &&
          part.state != ToolUiPartState.inputStreaming &&
          !(part.state == ToolUiPartState.approvalResponded &&
              !part.providerExecuted)) {
        throw StateError(
          'Tool call "$toolCallId" is not waiting for client-side output.',
        );
      }

      found = true;
      return transform(part);
    }).toList(growable: false);

    if (!found) {
      throw StateError('No tool call with ID "$toolCallId" was found.');
    }

    return ChatUiMessage(
      id: message.id,
      role: message.role,
      parts: parts,
      metadata: message.metadata,
    );
  }

  ChatUiMessage _updateToolPartByApprovalId(
    ChatUiMessage message,
    String approvalId,
    ToolUiPart Function(ToolUiPart part) transform,
  ) {
    var found = false;

    final parts = message.parts.map((part) {
      if (part is! ToolUiPart || part.approval?.approvalId != approvalId) {
        return part;
      }

      if (part.state != ToolUiPartState.approvalRequested) {
        throw StateError(
          'Approval "$approvalId" is not waiting for a response.',
        );
      }

      found = true;
      return transform(part);
    }).toList(growable: false);

    if (!found) {
      throw StateError('No tool approval with ID "$approvalId" was found.');
    }

    return ChatUiMessage(
      id: message.id,
      role: message.role,
      parts: parts,
      metadata: message.metadata,
    );
  }

  static List<ChatUiMessage> _visibleMessagesFromPrompt(
    List<PromptMessage> prompt,
  ) {
    return prompt
        .asMap()
        .entries
        .map(
          (entry) => _promptMessageToUiMessage(
            entry.value,
            id: 'seed-${entry.key}',
          ),
        )
        .toList(growable: false);
  }

  static ChatUiMessage _promptMessageToUiMessage(
    PromptMessage message, {
    required String id,
  }) {
    final parts = <ChatUiPart>[];

    void upsertToolPart(
      String toolCallId,
      ToolUiPart Function(ToolUiPart? current) build,
    ) {
      final index = parts.lastIndexWhere(
        (part) => part is ToolUiPart && part.toolCallId == toolCallId,
      );
      final current = index == -1 ? null : parts[index] as ToolUiPart;
      final next = build(current);

      if (index == -1) {
        parts.add(next);
      } else {
        parts[index] = next;
      }
    }

    for (final part in message.parts) {
      switch (part) {
        case TextPromptPart(
            :final text,
            :final providerMetadata,
          ):
          parts.add(
            TextUiPart(
              text: text,
              providerMetadata: providerMetadata,
            ),
          );
        case ReasoningPromptPart(
            :final text,
            :final providerMetadata,
          ):
          parts.add(
            ReasoningUiPart(
              text: text,
              providerMetadata: providerMetadata,
            ),
          );
        case FilePromptPart(
            :final mediaType,
            :final filename,
            :final uri,
            :final bytes,
            :final providerMetadata,
          ):
          parts.add(
            FileUiPart(
              GeneratedFile(
                mediaType: mediaType,
                filename: filename,
                uri: uri,
                bytes: bytes,
              ),
              providerMetadata: providerMetadata,
            ),
          );
        case ReasoningFilePromptPart(
            :final mediaType,
            :final filename,
            :final uri,
            :final bytes,
            :final providerMetadata,
          ):
          parts.add(
            ReasoningFileUiPart(
              GeneratedFile(
                mediaType: mediaType,
                filename: filename,
                uri: uri,
                bytes: bytes,
              ),
              providerMetadata: providerMetadata,
            ),
          );
        case ImagePromptPart(
            :final mediaType,
            :final uri,
            :final bytes,
            :final providerMetadata,
          ):
          parts.add(
            FileUiPart(
              GeneratedFile(
                mediaType: mediaType,
                uri: uri,
                bytes: bytes,
              ),
              providerMetadata: providerMetadata,
            ),
          );
        case CustomPromptPart(
            :final kind,
            :final data,
            :final providerMetadata,
          ):
          parts.add(
            CustomUiPart(
              kind: kind,
              data: data,
              providerMetadata: providerMetadata,
            ),
          );
        case ToolCallPromptPart(
            :final toolCallId,
            :final toolName,
            :final input,
            :final providerExecuted,
            :final isDynamic,
            :final title,
            :final providerMetadata,
          ):
          upsertToolPart(
            toolCallId,
            (current) => ToolUiPart(
              toolCallId: toolCallId,
              toolName: toolName,
              state: current?.approval != null
                  ? ToolUiPartState.approvalRequested
                  : ToolUiPartState.inputAvailable,
              input: input,
              inputText: current?.inputText,
              output: current?.output,
              errorText: current?.errorText,
              providerExecuted:
                  providerExecuted || current?.providerExecuted == true,
              isDynamic: isDynamic || current?.isDynamic == true,
              preliminary: current?.preliminary ?? false,
              title: title ?? current?.title,
              approval: current?.approval,
              callProviderMetadata: ProviderMetadata.mergeNullable(
                current?.callProviderMetadata,
                providerMetadata,
              ),
              resultProviderMetadata: current?.resultProviderMetadata,
            ),
          );
        case ToolApprovalRequestPromptPart(
            :final approvalId,
            :final toolCallId,
            :final providerMetadata,
          ):
          upsertToolPart(
            toolCallId,
            (current) => ToolUiPart(
              toolCallId: toolCallId,
              toolName: current?.toolName ??
                  (message is ToolPromptMessage ? message.toolName : 'tool'),
              state: ToolUiPartState.approvalRequested,
              input: current?.input,
              inputText: current?.inputText,
              output: current?.output,
              errorText: current?.errorText,
              providerExecuted: current?.providerExecuted ?? false,
              isDynamic: current?.isDynamic ?? false,
              preliminary: current?.preliminary ?? false,
              title: current?.title,
              approval: ToolApprovalUiState(
                approvalId: approvalId,
              ),
              callProviderMetadata: ProviderMetadata.mergeNullable(
                current?.callProviderMetadata,
                providerMetadata,
              ),
              resultProviderMetadata: current?.resultProviderMetadata,
            ),
          );
        case ToolResultPromptPart(
            :final toolCallId,
            :final toolName,
            :final output,
            :final isError,
            :final providerMetadata,
          ):
          upsertToolPart(
            toolCallId,
            (current) => ToolUiPart(
              toolCallId: toolCallId,
              toolName: toolName,
              state: isError
                  ? ToolUiPartState.outputError
                  : ToolUiPartState.outputAvailable,
              input: current?.input,
              inputText: current?.inputText,
              output: output,
              errorText: isError ? '$output' : null,
              providerExecuted: current?.providerExecuted ?? false,
              isDynamic: current?.isDynamic ?? false,
              preliminary: false,
              title: current?.title,
              approval: current?.approval,
              callProviderMetadata: current?.callProviderMetadata,
              resultProviderMetadata: ProviderMetadata.mergeNullable(
                current?.resultProviderMetadata,
                providerMetadata,
              ),
            ),
          );
        case ToolApprovalResponsePromptPart(
            :final approvalId,
            :final toolCallId,
            :final approved,
            :final reason,
            :final providerMetadata,
          ):
          upsertToolPart(
            toolCallId,
            (current) => ToolUiPart(
              toolCallId: toolCallId,
              toolName: current?.toolName ??
                  (message is ToolPromptMessage ? message.toolName : 'tool'),
              state: approved
                  ? ToolUiPartState.approvalResponded
                  : ToolUiPartState.outputDenied,
              input: current?.input,
              inputText: current?.inputText,
              output: current?.output,
              errorText: current?.errorText,
              providerExecuted: current?.providerExecuted ?? false,
              isDynamic: current?.isDynamic ?? false,
              preliminary: current?.preliminary ?? false,
              title: current?.title,
              approval: ToolApprovalUiState(
                approvalId: approvalId,
                approved: approved,
                reason: reason,
              ),
              callProviderMetadata: ProviderMetadata.mergeNullable(
                current?.callProviderMetadata,
                providerMetadata,
              ),
              resultProviderMetadata: current?.resultProviderMetadata,
            ),
          );
      }
    }

    return ChatUiMessage(
      id: id,
      role: switch (message.role) {
        PromptRole.system => ChatUiRole.system,
        PromptRole.user => ChatUiRole.user,
        PromptRole.assistant || PromptRole.tool => ChatUiRole.assistant,
      },
      parts: parts,
    );
  }

  static List<PromptMessage> _assistantPromptMessagesFromUi(
    ChatUiMessage message, {
    int startPartIndex = 0,
  }) {
    final prompt = <PromptMessage>[];
    final assistantParts = <PromptPart>[];
    final replayedToolResultIds = {
      for (final part in message.parts.skip(startPartIndex))
        if (part case CustomUiPart(:final data))
          if (_toolReplayPayloadRole(data) == 'tool')
            if (_toolReplayPayloadToolCallId(data) case final String toolCallId)
              toolCallId,
    };

    void flushAssistantParts() {
      if (assistantParts.isEmpty) {
        return;
      }

      prompt.add(
        AssistantPromptMessage(
          parts: List<PromptPart>.from(assistantParts),
        ),
      );
      assistantParts.clear();
    }

    for (final part in message.parts.skip(startPartIndex)) {
      switch (part) {
        case TextUiPart(
              :final text,
              :final providerMetadata,
            )
            when text.isNotEmpty || providerMetadata != null:
          assistantParts.add(
            TextPromptPart(
              text,
              providerMetadata: providerMetadata,
            ),
          );
        case ReasoningUiPart(
              :final text,
              :final providerMetadata,
            )
            when text.isNotEmpty || providerMetadata != null:
          assistantParts.add(
            ReasoningPromptPart(
              text,
              providerMetadata: providerMetadata,
            ),
          );
        case FileUiPart(
            :final file,
            :final providerMetadata,
          ):
          assistantParts.add(
            FilePromptPart(
              mediaType: file.mediaType,
              filename: file.filename,
              uri: file.uri,
              bytes: file.bytes,
              providerMetadata: providerMetadata,
            ),
          );
        case ReasoningFileUiPart(
            :final file,
            :final providerMetadata,
          ):
          assistantParts.add(
            ReasoningFilePromptPart(
              mediaType: file.mediaType,
              filename: file.filename,
              uri: file.uri,
              bytes: file.bytes,
              providerMetadata: providerMetadata,
            ),
          );
        case CustomUiPart(
              :final kind,
              :final data,
              :final providerMetadata,
            )
            when _toolReplayPayloadRole(data) == 'tool':
          flushAssistantParts();
          prompt.add(
            ToolPromptMessage(
              toolName: _toolReplayPayloadToolName(data) ?? 'tool',
              parts: [
                CustomPromptPart(
                  kind: kind,
                  data: data,
                  providerMetadata: providerMetadata,
                ),
              ],
            ),
          );
        case CustomUiPart(
            :final kind,
            :final data,
            :final providerMetadata,
          ):
          assistantParts.add(
            CustomPromptPart(
              kind: kind,
              data: data,
              providerMetadata: providerMetadata,
            ),
          );
        case ToolUiPart(
              :final toolCallId,
              :final toolName,
              :final input,
              :final state,
              :final providerExecuted,
              :final isDynamic,
              :final title,
              :final approval,
              :final callProviderMetadata,
            )
            when state != ToolUiPartState.outputDenied &&
                state != ToolUiPartState.outputAvailable &&
                state != ToolUiPartState.outputError:
          assistantParts.add(
            ToolCallPromptPart(
              toolCallId: toolCallId,
              toolName: toolName,
              input: input,
              providerExecuted: providerExecuted,
              isDynamic: isDynamic,
              title: title,
              providerMetadata: callProviderMetadata,
            ),
          );
          if (approval != null) {
            assistantParts.add(
              ToolApprovalRequestPromptPart(
                approvalId: approval.approvalId,
                toolCallId: toolCallId,
                providerMetadata: callProviderMetadata,
              ),
            );
          }
        case ToolUiPart(
              :final toolCallId,
              :final toolName,
              :final input,
              :final state,
              :final providerExecuted,
              :final isDynamic,
              :final title,
              :final callProviderMetadata,
              :final output,
              :final resultProviderMetadata,
            )
            when state == ToolUiPartState.outputAvailable ||
                state == ToolUiPartState.outputError:
          if (!providerExecuted) {
            break;
          }

          assistantParts.add(
            ToolCallPromptPart(
              toolCallId: toolCallId,
              toolName: toolName,
              input: input,
              providerExecuted: providerExecuted,
              isDynamic: isDynamic,
              title: title,
              providerMetadata: callProviderMetadata,
            ),
          );
          flushAssistantParts();

          if (replayedToolResultIds.contains(toolCallId)) {
            break;
          }

          prompt.add(
            ToolPromptMessage(
              toolName: toolName,
              parts: [
                ToolResultPromptPart(
                  toolCallId: toolCallId,
                  toolName: toolName,
                  output: output,
                  isError: state == ToolUiPartState.outputError,
                  providerMetadata: resultProviderMetadata,
                ),
              ],
            ),
          );
        case StepBoundaryUiPart():
        case SourceUiPart():
        case DataUiPart():
        default:
          break;
      }
    }

    flushAssistantParts();
    return prompt;
  }
}

String? _toolReplayPayloadRole(Object? data) {
  final payload = _toolReplayPayloadMap(data);
  final role = payload?['replayRole'];
  return role is String && role.isNotEmpty ? role : null;
}

String? _toolReplayPayloadToolCallId(Object? data) {
  final payload = _toolReplayPayloadMap(data);
  final toolCallId = payload?['toolCallId'];
  return toolCallId is String && toolCallId.isNotEmpty ? toolCallId : null;
}

String? _toolReplayPayloadToolName(Object? data) {
  final payload = _toolReplayPayloadMap(data);
  final toolName = payload?['toolName'];
  return toolName is String && toolName.isNotEmpty ? toolName : null;
}

Map<String, Object?>? _toolReplayPayloadMap(Object? data) {
  if (data is Map<String, Object?>) {
    return data;
  }

  if (data is Map) {
    final normalized = <String, Object?>{};
    for (final entry in data.entries) {
      if (entry.key is! String) {
        return null;
      }

      normalized[entry.key as String] = entry.value;
    }
    return normalized;
  }

  return null;
}

ChatStatus _normalizeRestoredStatus(ChatStatus status) {
  return switch (status) {
    ChatStatus.submitting || ChatStatus.streaming => ChatStatus.ready,
    _ => status,
  };
}

Object? _normalizeRestoredError(ChatStatus status, Object? error) {
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
