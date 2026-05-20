import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session_message_support.dart';
import 'chat_session.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';
import 'chat_transport.dart';
import 'default_chat_session_active_turn.dart';
import 'default_chat_session_state_controller.dart';
import 'default_chat_session_support.dart';
import 'default_chat_session_transcript.dart';
import 'default_chat_session_tool_execution.dart';
import 'default_chat_session_tool_interactions.dart';
import 'tool_execution_registry.dart';

final class DefaultChatSession implements ChatSession {
  final ChatTransport transport;
  final ChatOnToolCall? onToolCall;
  late final DefaultChatSessionActiveTurn _activeTurn;
  late final DefaultChatSessionToolExecutionScheduler _toolExecutionScheduler;
  late final DefaultChatSessionToolInteractions _toolInteractions;
  final DefaultChatSessionStateController _stateController;
  final DefaultChatSessionTranscript _transcript;
  final MessageIdGenerator _messageIdGenerator;

  DefaultChatSession({
    required ChatTransport transport,
    String? chatId,
    List<ModelMessage> initialMessages = const [],
    MessageIdGenerator? messageIdGenerator,
    ChatOnToolCall? onToolCall,
    ToolExecutionRegistry? toolExecutionRegistry,
  }) : this._(
          transport: transport,
          onToolCall: resolveChatToolExecutionCallback(
            onToolCall: onToolCall,
            toolExecutionRegistry: toolExecutionRegistry,
          ),
          initialState: ChatState(
            chatId: chatId ?? 'chat-${DateTime.now().microsecondsSinceEpoch}',
            messages: visibleMessagesFromPrompt(
              normalizeModelMessages(initialMessages),
            ),
          ),
          initialPrompt: normalizeModelMessages(initialMessages),
          messageIdGenerator: messageIdGenerator,
        );

  DefaultChatSession.withPromptHistory({
    required ChatTransport transport,
    String? chatId,
    List<PromptMessage> initialPrompt = const [],
    MessageIdGenerator? messageIdGenerator,
    ChatOnToolCall? onToolCall,
    ToolExecutionRegistry? toolExecutionRegistry,
  }) : this._(
          transport: transport,
          onToolCall: resolveChatToolExecutionCallback(
            onToolCall: onToolCall,
            toolExecutionRegistry: toolExecutionRegistry,
          ),
          initialState: ChatState(
            chatId: chatId ?? 'chat-${DateTime.now().microsecondsSinceEpoch}',
            messages: visibleMessagesFromPrompt(initialPrompt),
          ),
          initialPrompt: List.unmodifiable(initialPrompt),
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
          onToolCall: resolveChatToolExecutionCallback(
            onToolCall: onToolCall,
            toolExecutionRegistry: toolExecutionRegistry,
          ),
          initialState: ChatState(
            chatId: snapshot.chatId,
            messages: snapshot.messages,
            status: normalizeRestoredChatStatus(snapshot.status),
            error: normalizeRestoredChatError(snapshot.status, snapshot.error),
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
  })  : _stateController = DefaultChatSessionStateController(initialState),
        _messageIdGenerator = messageIdGenerator ??
            sequentialChatMessageId(
              existingIds: initialState.messages.map((message) => message.id),
            ),
        _transcript = DefaultChatSessionTranscript(initialPrompt),
        assert(initialState.chatId.isNotEmpty) {
    _toolInteractions = DefaultChatSessionToolInteractions(_transcript);
    _activeTurn = DefaultChatSessionActiveTurn(
      readState: () => _stateController.state,
      emitState: _stateController.emitState,
      upsertAssistantMessage: _upsertAssistantMessage,
      appendAssistantPromptIfPresent: _appendAssistantPromptIfPresent,
      emitTransientDataPart: _stateController.emitTransientDataPart,
      scheduleAutomaticToolExecution: _maybeScheduleAutomaticToolExecution,
      mapError: chatSessionErrorToModelError,
    );
    _toolExecutionScheduler = DefaultChatSessionToolExecutionScheduler(
      onToolCall: onToolCall,
      isDisposed: () => _stateController.isDisposed,
      hasActiveTurn: () => _activeTurn.hasActiveTurn,
      readState: () => _stateController.state,
      applyToolOutput: addToolOutput,
    );
    _maybeScheduleAutomaticToolExecution();
  }

  @override
  ChatState get state => _stateController.state;

  @override
  Stream<ChatState> get states => _stateController.states;

  @override
  Stream<DataUiPart<Object?>> get transientDataParts =>
      _stateController.transientDataParts;

  @override
  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    _ensureUsable();
    _ensureIdle('sendMessage');

    final userAppend = _transcript.appendUserInput(
      input,
      messageId: _messageIdGenerator(),
    );
    _stateController.emitState(
      _stateController.state.copyWith(
        messages: [..._stateController.state.messages, userAppend.uiMessage],
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
        (_stateController.state.messages.isEmpty ||
            _stateController.state.messages.last.id != messageId)) {
      throw UnsupportedError(
        'Regenerating a non-latest message has not been implemented yet.',
      );
    }

    _transcript.removeTrailingAssistantPrompt();
    final currentMessages = _transcript
        .removeTrailingAssistantMessage(_stateController.state.messages);

    _stateController.emitState(
      _stateController.state.copyWith(
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

    final result = _toolInteractions.applyToolOutput(
      messages: _stateController.state.messages,
      update: update,
    );

    _stateController.emitState(
      _stateController.state.copyWith(
        messages: _transcript.replaceLatestAssistantMessage(
          _stateController.state.messages,
          result.assistantMessage,
        ),
        status: result.status,
        error: null,
      ),
    );

    final continuation = result.continuation;
    if (continuation == null && result.shouldScheduleAutomaticToolExecution) {
      _maybeScheduleAutomaticToolExecution();
      return Future.value();
    }

    if (continuation == null) {
      return Future.value();
    }

    return _runAssistantTurn(
      options: continuation.options,
      trigger: continuation.trigger,
      seedAssistantMessage: result.assistantMessage,
    );
  }

  @override
  Future<void> addDataPart<T>(DataUiPart<T> part) async {
    _ensureUsable();

    if (_activeTurn.applyDataPart(part)) {
      return;
    }

    if (_stateController.state.status != ChatStatus.awaitingTool &&
        _stateController.state.status != ChatStatus.awaitingApproval) {
      throw StateError(
        'Cannot call addDataPart unless the current assistant turn is active or waiting for tool or approval input.',
      );
    }

    final assistantMessage = _transcript
        .requireLatestAssistantMessage(_stateController.state.messages);
    final updatedAssistantMessage = ChatUiAccumulator(
      messageId: assistantMessage.id,
      seedMessage: assistantMessage,
    ).applyDataPart(part);

    _stateController.emitState(
      _stateController.state.copyWith(
        messages: _transcript.replaceLatestAssistantMessage(
          _stateController.state.messages,
          updatedAssistantMessage,
        ),
        error: null,
      ),
    );
  }

  @override
  Future<void> respondToolApproval(ToolApprovalResponse response) async {
    _ensureUsable();
    _ensureIdle('respondToolApproval');

    final result = _toolInteractions.applyToolApproval(
      messages: _stateController.state.messages,
      response: response,
    );

    final continuation = result.continuation;
    if (continuation != null) {
      _stateController.emitState(
        _stateController.state.copyWith(
          messages: _transcript.replaceLatestAssistantMessage(
            _stateController.state.messages,
            result.assistantMessage,
          ),
          status: result.status,
          error: null,
        ),
      );

      return _runAssistantTurn(
        options: continuation.options,
        trigger: continuation.trigger,
        seedAssistantMessage: result.assistantMessage,
      );
    }

    _stateController.emitState(
      _stateController.state.copyWith(
        messages: _transcript.replaceLatestAssistantMessage(
          _stateController.state.messages,
          result.assistantMessage,
        ),
        status: result.status,
        error: null,
      ),
    );
    if (result.shouldScheduleAutomaticToolExecution) {
      _maybeScheduleAutomaticToolExecution();
    }
  }

  @override
  Future<void> resume() async {
    _ensureUsable();
    _ensureIdle('resume');

    if (_stateController.state.status != ChatStatus.error) {
      throw StateError(
        'Cannot call resume unless the chat session is in the error state.',
      );
    }

    final stream = transport.reconnect(_stateController.state.chatId);
    if (stream == null) {
      throw StateError(
        'The configured chat transport does not have reconnect state for chat "${_stateController.state.chatId}".',
      );
    }

    final detachedAssistant = _transcript
        .detachTrailingAssistantMessage(_stateController.state.messages);

    _stateController.emitState(
      _stateController.state.copyWith(
        messages: detachedAssistant.messages,
        status: ChatStatus.streaming,
        error: null,
      ),
    );

    await _activeTurn.consume(
      stream: stream,
      assistantMessageId:
          detachedAssistant.assistantMessage?.id ?? _messageIdGenerator(),
      promptAppendStartIndex: 0,
    );
  }

  @override
  Future<void> stop() async {
    _ensureUsable();
    await _activeTurn.stop();
  }

  @override
  Future<void> clearError() async {
    _ensureUsable();
    _stateController.emitState(
      _stateController.state.copyWith(
        status: ChatStatus.ready,
        error: null,
      ),
    );
  }

  @override
  ChatSessionSnapshot exportSnapshot() {
    _ensureUsable();
    if (_activeTurn.hasActiveTurn) {
      throw StateError(
        'Cannot export a chat snapshot while an assistant turn is still active.',
      );
    }

    return _transcript.snapshot(_stateController.state);
  }

  @override
  Future<void> dispose() async {
    if (_stateController.isDisposed) {
      return;
    }

    await _activeTurn.dispose();
    await _stateController.dispose();
  }

  Future<void> _runAssistantTurn({
    required ChatRequestOptions options,
    required ChatTransportTrigger trigger,
    ChatUiMessage? seedAssistantMessage,
  }) async {
    _stateController.emitState(
      _stateController.state.copyWith(
        status: ChatStatus.streaming,
        error: null,
      ),
    );

    final stream = transport.sendMessages(
      ChatTransportRequest(
        chatId: _stateController.state.chatId,
        trigger: trigger,
        prompt: _transcript.prompt,
        options: options,
      ),
    );

    await _activeTurn.consume(
      stream: stream,
      assistantMessageId: seedAssistantMessage?.id ?? _messageIdGenerator(),
      seedAssistantMessage: seedAssistantMessage,
      promptAppendStartIndex: seedAssistantMessage?.parts.length ?? 0,
      syntheticStepStartOnSeed: true,
    );
  }

  void _appendAssistantPromptIfPresent(
    ChatUiMessage assistantMessage, {
    int startPartIndex = 0,
  }) {
    _transcript.appendAssistantPromptIfPresent(
      assistantMessage,
      startPartIndex: startPartIndex,
    );
  }

  void _upsertAssistantMessage(ChatUiMessage assistantMessage) {
    _stateController.emitState(
      _stateController.state.copyWith(
        messages: _transcript.upsertAssistantMessage(
          _stateController.state.messages,
          assistantMessage,
        ),
        error: null,
      ),
    );
  }

  void _maybeScheduleAutomaticToolExecution() {
    _toolExecutionScheduler.maybeSchedule();
  }

  void _ensureUsable() {
    _stateController.ensureUsable();
  }

  void _ensureIdle(String operation) {
    if (_activeTurn.hasActiveTurn) {
      throw StateError(
        'Cannot call $operation while another assistant turn is still active.',
      );
    }
  }
}
