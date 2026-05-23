import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session.dart';
import 'chat_state.dart';
import 'chat_transport.dart';
import 'default_chat_session_active_turn.dart';
import 'default_chat_session_state_controller.dart';
import 'default_chat_session_support.dart';
import 'default_chat_session_tool_execution.dart';
import 'default_chat_session_tool_interactions.dart';
import 'default_chat_session_transcript.dart';

final class DefaultChatSessionTurnLifecycle {
  final ChatTransport transport;
  final ChatOnToolCall? onToolCall;
  final DefaultChatSessionStateController stateController;
  final DefaultChatSessionTranscript transcript;
  final MessageIdGenerator messageIdGenerator;

  late final DefaultChatSessionActiveTurn _activeTurn;
  late final DefaultChatSessionToolExecutionScheduler _toolExecutionScheduler;
  late final DefaultChatSessionToolInteractions _toolInteractions;

  DefaultChatSessionTurnLifecycle({
    required this.transport,
    required this.onToolCall,
    required this.stateController,
    required this.transcript,
    required this.messageIdGenerator,
  }) {
    _toolInteractions = DefaultChatSessionToolInteractions(transcript);
    _activeTurn = DefaultChatSessionActiveTurn(
      readState: () => stateController.state,
      emitState: stateController.emitState,
      upsertAssistantMessage: _upsertAssistantMessage,
      appendAssistantPromptIfPresent: _appendAssistantPromptIfPresent,
      emitTransientDataPart: stateController.emitTransientDataPart,
      scheduleAutomaticToolExecution: _maybeScheduleAutomaticToolExecution,
      mapError: chatSessionErrorToModelError,
    );
    _toolExecutionScheduler = DefaultChatSessionToolExecutionScheduler(
      onToolCall: onToolCall,
      isDisposed: () => stateController.isDisposed,
      hasActiveTurn: () => _activeTurn.hasActiveTurn,
      readState: () => stateController.state,
      applyToolOutput: addToolOutput,
    );
  }

  bool get hasActiveTurn => _activeTurn.hasActiveTurn;

  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    _ensureUsable();
    _ensureIdle('sendMessage');

    final userAppend = transcript.appendUserInput(
      input,
      messageId: messageIdGenerator(),
    );
    stateController.emitState(
      stateController.state.copyWith(
        messages: [...stateController.state.messages, userAppend.uiMessage],
        status: ChatStatus.submitting,
        error: null,
      ),
    );

    await _runAssistantTurn(
      options: options,
      trigger: ChatTransportTrigger.sendMessage,
    );
  }

  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    _ensureUsable();
    _ensureIdle('regenerate');

    if (messageId != null &&
        (stateController.state.messages.isEmpty ||
            stateController.state.messages.last.id != messageId)) {
      throw UnsupportedError(
        'Regenerating a non-latest message has not been implemented yet.',
      );
    }

    transcript.removeTrailingAssistantPrompt();
    final currentMessages = transcript
        .removeTrailingAssistantMessage(stateController.state.messages);

    stateController.emitState(
      stateController.state.copyWith(
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

  Future<void> addToolOutput(ToolOutputUpdate update) {
    _ensureUsable();
    _ensureIdle('addToolOutput');

    final result = _toolInteractions.applyToolOutput(
      messages: stateController.state.messages,
      update: update,
    );

    stateController.emitState(
      stateController.state.copyWith(
        messages: transcript.replaceLatestAssistantMessage(
          stateController.state.messages,
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

  Future<void> addDataPart<T>(DataUiPart<T> part) async {
    _ensureUsable();

    if (_activeTurn.applyDataPart(part)) {
      return;
    }

    if (stateController.state.status != ChatStatus.awaitingTool &&
        stateController.state.status != ChatStatus.awaitingApproval) {
      throw StateError(
        'Cannot call addDataPart unless the current assistant turn is active or waiting for tool or approval input.',
      );
    }

    final assistantMessage = transcript
        .requireLatestAssistantMessage(stateController.state.messages);
    final updatedAssistantMessage = ChatUiAccumulator(
      messageId: assistantMessage.id,
      seedMessage: assistantMessage,
    ).applyDataPart(part);

    stateController.emitState(
      stateController.state.copyWith(
        messages: transcript.replaceLatestAssistantMessage(
          stateController.state.messages,
          updatedAssistantMessage,
        ),
        error: null,
      ),
    );
  }

  Future<void> respondToolApproval(ToolApprovalResponse response) async {
    _ensureUsable();
    _ensureIdle('respondToolApproval');

    final result = _toolInteractions.applyToolApproval(
      messages: stateController.state.messages,
      response: response,
    );

    final continuation = result.continuation;
    if (continuation != null) {
      stateController.emitState(
        stateController.state.copyWith(
          messages: transcript.replaceLatestAssistantMessage(
            stateController.state.messages,
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

    stateController.emitState(
      stateController.state.copyWith(
        messages: transcript.replaceLatestAssistantMessage(
          stateController.state.messages,
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

  Future<void> resume() async {
    _ensureUsable();
    _ensureIdle('resume');

    if (stateController.state.status != ChatStatus.error) {
      throw StateError(
        'Cannot call resume unless the chat session is in the error state.',
      );
    }

    final stream = transport.reconnect(stateController.state.chatId);
    if (stream == null) {
      throw StateError(
        'The configured chat transport does not have reconnect state for chat "${stateController.state.chatId}".',
      );
    }

    final detachedAssistant = transcript
        .detachTrailingAssistantMessage(stateController.state.messages);

    stateController.emitState(
      stateController.state.copyWith(
        messages: detachedAssistant.messages,
        status: ChatStatus.streaming,
        error: null,
      ),
    );

    await _activeTurn.consume(
      stream: stream,
      assistantMessageId:
          detachedAssistant.assistantMessage?.id ?? messageIdGenerator(),
      promptAppendStartIndex: 0,
    );
  }

  Future<void> stop() async {
    _ensureUsable();
    await _activeTurn.stop();
  }

  Future<void> clearError() async {
    _ensureUsable();
    stateController.emitState(
      stateController.state.copyWith(
        status: ChatStatus.ready,
        error: null,
      ),
    );
  }

  Future<void> dispose() async {
    await _activeTurn.dispose();
  }

  void maybeScheduleAutomaticToolExecution() {
    _maybeScheduleAutomaticToolExecution();
  }

  Future<void> _runAssistantTurn({
    required ChatRequestOptions options,
    required ChatTransportTrigger trigger,
    ChatUiMessage? seedAssistantMessage,
  }) async {
    stateController.emitState(
      stateController.state.copyWith(
        status: ChatStatus.streaming,
        error: null,
      ),
    );

    final stream = transport.sendMessages(
      ChatTransportRequest(
        chatId: stateController.state.chatId,
        trigger: trigger,
        prompt: transcript.prompt,
        options: options,
      ),
    );

    await _activeTurn.consume(
      stream: stream,
      assistantMessageId: seedAssistantMessage?.id ?? messageIdGenerator(),
      seedAssistantMessage: seedAssistantMessage,
      promptAppendStartIndex: seedAssistantMessage?.parts.length ?? 0,
      syntheticStepStartOnSeed: true,
    );
  }

  void _appendAssistantPromptIfPresent(
    ChatUiMessage assistantMessage, {
    int startPartIndex = 0,
  }) {
    transcript.appendAssistantPromptIfPresent(
      assistantMessage,
      startPartIndex: startPartIndex,
    );
  }

  void _upsertAssistantMessage(ChatUiMessage assistantMessage) {
    stateController.emitState(
      stateController.state.copyWith(
        messages: transcript.upsertAssistantMessage(
          stateController.state.messages,
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
    stateController.ensureUsable();
  }

  void _ensureIdle(String operation) {
    if (_activeTurn.hasActiveTurn) {
      throw StateError(
        'Cannot call $operation while another assistant turn is still active.',
      );
    }
  }
}
