import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session.dart';
import 'chat_state.dart';
import 'chat_transport.dart';

typedef MessageIdGenerator = String Function();

final class DefaultChatSession implements ChatSession {
  final ChatTransport transport;
  final StreamController<ChatState> _statesController;
  final List<PromptMessage> _promptHistory = [];
  final MessageIdGenerator _messageIdGenerator;

  ChatState _state;
  StreamSubscription<TextStreamEvent>? _activeSubscription;
  ChatUiAccumulator? _activeAccumulator;
  Completer<void>? _activeCompletion;
  bool _isDisposed = false;

  DefaultChatSession({
    required this.transport,
    String? chatId,
    List<PromptMessage> initialPrompt = const [],
    MessageIdGenerator? messageIdGenerator,
  })  : _statesController = StreamController<ChatState>.broadcast(sync: true),
        _messageIdGenerator = messageIdGenerator ?? _sequentialMessageId(),
        _state = ChatState(
          chatId: chatId ?? 'chat-${DateTime.now().microsecondsSinceEpoch}',
          messages: _visibleMessagesFromPrompt(initialPrompt),
        ) {
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
    throw UnsupportedError(
      'Client-side tool output injection has not been implemented yet.',
    );
  }

  @override
  Future<void> respondToolApproval(ToolApprovalResponse response) {
    throw UnsupportedError(
      'Tool approval response handling has not been implemented yet.',
    );
  }

  @override
  Future<void> resume() async {
    throw UnsupportedError(
      'Transport reconnect / resume has not been implemented yet.',
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
      _appendAssistantPromptIfPresent(assistantMessage);
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
  }) async {
    final assistantMessageId = _messageIdGenerator();
    final accumulator = ChatUiAccumulator(messageId: assistantMessageId);
    final completion = Completer<void>();
    var completed = false;
    ChatUiMessage? latestAssistantMessage;

    _activeAccumulator = accumulator;
    _activeCompletion = completion;
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

    _activeSubscription = stream.listen(
      (event) async {
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
          _appendAssistantPromptIfPresent(latestAssistantMessage!);
          _clearActiveTurn();
          _emitState(
            _state.copyWith(
              status: ChatStatus.ready,
              error: null,
            ),
          );
          if (!completion.isCompleted) {
            completion.complete();
          }
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
          _appendAssistantPromptIfPresent(latestAssistantMessage!);
        }

        _clearActiveTurn();
        _emitState(
          _state.copyWith(
            status: ChatStatus.ready,
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

  void _appendAssistantPromptIfPresent(ChatUiMessage assistantMessage) {
    final promptMessage = _assistantPromptMessageFromUi(assistantMessage);
    if (promptMessage != null) {
      _promptHistory.add(promptMessage);
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
    return ChatUiMessage(
      id: id,
      role: switch (message.role) {
        PromptRole.system => ChatUiRole.system,
        PromptRole.user => ChatUiRole.user,
        PromptRole.assistant || PromptRole.tool => ChatUiRole.assistant,
      },
      parts: message.parts
          .map(
            (part) => switch (part) {
              TextPromptPart(:final text) => TextUiPart(text: text),
              FilePromptPart(
                :final mediaType,
                :final filename,
                :final uri,
                :final bytes,
              ) =>
                FileUiPart(
                  GeneratedFile(
                    mediaType: mediaType,
                    filename: filename,
                    uri: uri,
                    bytes: bytes,
                  ),
                ),
              ImagePromptPart(
                :final mediaType,
                :final uri,
                :final bytes,
              ) =>
                FileUiPart(
                  GeneratedFile(
                    mediaType: mediaType,
                    uri: uri,
                    bytes: bytes,
                  ),
                ),
              ToolCallPromptPart(
                :final toolCallId,
                :final toolName,
                :final input,
              ) =>
                ToolUiPart(
                  toolCallId: toolCallId,
                  toolName: toolName,
                  state: ToolUiPartState.inputAvailable,
                  input: input,
                ),
              ToolResultPromptPart(
                :final toolCallId,
                :final toolName,
                :final output,
                :final isError,
              ) =>
                ToolUiPart(
                  toolCallId: toolCallId,
                  toolName: toolName,
                  state: isError
                      ? ToolUiPartState.outputError
                      : ToolUiPartState.outputAvailable,
                  output: output,
                  errorText: isError ? '$output' : null,
                ),
            },
          )
          .toList(growable: false),
    );
  }

  static AssistantPromptMessage? _assistantPromptMessageFromUi(
    ChatUiMessage message,
  ) {
    final parts = <PromptPart>[];

    for (final part in message.parts) {
      switch (part) {
        case TextUiPart(:final text) when text.isNotEmpty:
          parts.add(TextPromptPart(text));
        case FileUiPart(:final file):
          parts.add(
            FilePromptPart(
              mediaType: file.mediaType,
              filename: file.filename,
              uri: file.uri,
              bytes: file.bytes,
            ),
          );
        case ToolUiPart(
              :final toolCallId,
              :final toolName,
              :final input,
              :final state,
            )
            when state != ToolUiPartState.outputDenied:
          parts.add(
            ToolCallPromptPart(
              toolCallId: toolCallId,
              toolName: toolName,
              input: input,
            ),
          );
        default:
          break;
      }
    }

    if (parts.isEmpty) {
      return null;
    }

    return AssistantPromptMessage(parts: parts);
  }
}

MessageIdGenerator _sequentialMessageId() {
  var index = 0;
  return () {
    final value = 'msg-$index';
    index += 1;
    return value;
  };
}
