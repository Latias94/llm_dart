import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session_message_support.dart';
import 'chat_session.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';
import 'chat_transport.dart';
import 'default_chat_session_state_controller.dart';
import 'default_chat_session_support.dart';
import 'default_chat_session_transcript.dart';
import 'default_chat_session_turn_lifecycle.dart';
import 'tool_execution_registry.dart';

final class DefaultChatSession implements ChatSession {
  final ChatTransport transport;
  final ChatOnToolCall? onToolCall;
  late final DefaultChatSessionTurnLifecycle _turnLifecycle;
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
    _turnLifecycle = DefaultChatSessionTurnLifecycle(
      transport: transport,
      onToolCall: onToolCall,
      stateController: _stateController,
      transcript: _transcript,
      messageIdGenerator: _messageIdGenerator,
    );
    _turnLifecycle.maybeScheduleAutomaticToolExecution();
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
  }) =>
      _turnLifecycle.sendMessage(input, options: options);

  @override
  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  }) =>
      _turnLifecycle.regenerate(messageId: messageId, options: options);

  @override
  Future<void> addToolOutput(ToolOutputUpdate update) =>
      _turnLifecycle.addToolOutput(update);

  @override
  Future<void> addDataPart<T>(DataUiPart<T> part) =>
      _turnLifecycle.addDataPart(part);

  @override
  Future<void> respondToolApproval(ToolApprovalResponse response) =>
      _turnLifecycle.respondToolApproval(response);

  @override
  Future<void> resume() => _turnLifecycle.resume();

  @override
  Future<void> stop() => _turnLifecycle.stop();

  @override
  Future<void> clearError() => _turnLifecycle.clearError();

  @override
  ChatSessionSnapshot exportSnapshot() {
    _stateController.ensureUsable();
    if (_turnLifecycle.hasActiveTurn) {
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

    await _turnLifecycle.dispose();
    await _stateController.dispose();
  }
}
