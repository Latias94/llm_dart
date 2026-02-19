import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart' as core;

import 'handle_ui_message_stream_finish.dart';
import 'read_ui_message_stream.dart';
import 'serial_job_executor.dart';
import 'ui_messages.dart';

enum UiChatStatus {
  submitted,
  streaming,
  ready,
  error,
}

class UiChatRequestOptions {
  final Map<String, String>? headers;
  final Map<String, Object?>? body;
  final Object? metadata;

  const UiChatRequestOptions({
    this.headers,
    this.body,
    this.metadata,
  });
}

abstract class UiChatTransport {
  FutureOr<Stream<Map<String, Object?>>> sendMessages({
    required String chatId,
    required List<UIMessage> messages,
    required String trigger,
    String? messageId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
    core.CancelToken? cancelToken,
  });

  FutureOr<Stream<Map<String, Object?>>>? reconnectToStream({
    required String chatId,
    Map<String, String>? headers,
    Map<String, Object?>? body,
    Object? metadata,
  }) =>
      null;
}

abstract class UiChatState {
  UiChatStatus status = UiChatStatus.ready;
  Object? error;

  List<UIMessage> messages = const <UIMessage>[];

  void pushMessage(UIMessage message);
  void popMessage();
  void replaceMessage(int index, UIMessage message);

  T snapshot<T>(T value);
}

class InMemoryUiChatState extends UiChatState {
  @override
  List<UIMessage> messages;

  InMemoryUiChatState([List<UIMessage> initial = const <UIMessage>[]])
      : messages = List<UIMessage>.from(initial);

  @override
  void pushMessage(UIMessage message) {
    messages = [...messages, message];
  }

  @override
  void popMessage() {
    if (messages.isEmpty) return;
    messages = messages.sublist(0, messages.length - 1);
  }

  @override
  void replaceMessage(int index, UIMessage message) {
    if (index < 0 || index >= messages.length) return;
    messages = [
      ...messages.take(index),
      message,
      ...messages.skip(index + 1),
    ];
  }

  @override
  T snapshot<T>(T value) => value;
}

typedef UiChatOnErrorCallback = void Function(Object error);

class UiChatFinishEvent {
  final UIMessage message;
  final List<UIMessage> messages;
  final bool isAbort;
  final bool isError;
  final String? finishReason;

  const UiChatFinishEvent({
    required this.message,
    required this.messages,
    required this.isAbort,
    required this.isError,
    required this.finishReason,
  });
}

typedef UiChatOnFinishCallback = void Function(UiChatFinishEvent event);

class UiChatInit {
  final String? id;
  final List<UIMessage>? messages;
  final core.IdGenerator? generateId;
  final UiChatTransport transport;
  final UiChatOnErrorCallback? onError;
  final UiChatOnFinishCallback? onFinish;

  const UiChatInit({
    required this.transport,
    this.id,
    this.messages,
    this.generateId,
    this.onError,
    this.onFinish,
  });
}

/// A stateful UI chat helper inspired by Vercel AI SDK's `Chat`.
///
/// This class is transport-agnostic: provide a [UiChatTransport] that returns a
/// stream of UI message chunks (maps matching the AI SDK chunk schema).
class UiChat {
  final String id;
  final core.IdGenerator generateId;

  final UiChatState state;
  final UiChatTransport transport;

  final UiChatOnErrorCallback? _onError;
  final UiChatOnFinishCallback? _onFinish;

  final SerialJobExecutor _jobExecutor = SerialJobExecutor();

  core.CancelToken? _activeCancelToken;

  static core.IdGenerator _defaultIdGenerator(UiChatInit init) =>
      init.generateId ?? core.generateId;

  UiChat({
    required UiChatInit init,
    UiChatState? state,
  })  : generateId = _defaultIdGenerator(init),
        id = init.id ?? _defaultIdGenerator(init)(),
        transport = init.transport,
        _onError = init.onError,
        _onFinish = init.onFinish,
        state =
            state ?? InMemoryUiChatState(init.messages ?? const <UIMessage>[]) {
    this.state.status = UiChatStatus.ready;
    this.state.error = null;
  }

  UiChatStatus get status => state.status;
  Object? get error => state.error;
  List<UIMessage> get messages => state.messages;

  UIMessage? get _lastMessage =>
      state.messages.isEmpty ? null : state.messages.last;

  UIMessage? get _lastAssistantMessage {
    final last = _lastMessage;
    if (last?.role == 'assistant') return last;
    return null;
  }

  Future<void> stop([Object? reason]) async {
    _activeCancelToken?.cancel(reason ?? 'Cancelled');
  }

  void clearError() {
    if (state.status == UiChatStatus.error) {
      state.error = null;
      state.status = UiChatStatus.ready;
    }
  }

  Future<void> sendMessage(
    String text, {
    UiChatRequestOptions options = const UiChatRequestOptions(),
  }) {
    return _jobExecutor.run(() async {
      final message = UIMessage(
        id: generateId(),
        role: 'user',
        parts: [
          {'type': 'text', 'text': text},
        ],
      );

      state.pushMessage(message);

      await _makeRequest(
        trigger: 'submit-message',
        messageId: message.id,
        options: options,
      );
    });
  }

  Future<void> regenerate({
    String? messageId,
    UiChatRequestOptions options = const UiChatRequestOptions(),
  }) {
    return _jobExecutor.run(() async {
      final messages = state.messages;
      if (messages.isEmpty) {
        throw StateError('No messages to regenerate.');
      }

      final messageIndex = messageId == null
          ? messages.length - 1
          : messages.indexWhere((m) => m.id == messageId);

      if (messageIndex < 0) {
        throw StateError('Message $messageId not found.');
      }

      final target = messages[messageIndex];
      final keepCount =
          target.role == 'assistant' ? messageIndex : messageIndex + 1;
      state.messages = messages.take(keepCount).toList(growable: false);

      await _makeRequest(
        trigger: 'regenerate-message',
        messageId: messageId,
        options: options,
      );
    });
  }

  Future<void> resumeStream({
    UiChatRequestOptions options = const UiChatRequestOptions(),
  }) {
    return _jobExecutor.run(() async {
      await _makeRequest(trigger: 'resume-stream', options: options);
    });
  }

  Future<void> addToolApprovalResponse({
    required String id,
    required bool approved,
    String? reason,
  }) {
    return _jobExecutor.run(() async {
      final messages = state.messages;
      if (messages.isEmpty) return;

      final last = messages.last;
      final updatedParts = last.parts.map((part) {
        if (part['toolCallId'] == null) return part;
        if (part['state'] != 'approval-requested') return part;

        final approval = part['approval'];
        if (approval is! Map) return part;
        final approvalId = approval['id'];
        if (approvalId != id) return part;

        return <String, Object?>{
          ...part,
          'state': 'approval-responded',
          'approval': <String, Object?>{
            'id': id,
            'approved': approved,
            if (reason != null) 'reason': reason,
          },
        };
      }).toList(growable: false);

      state.replaceMessage(
          messages.length - 1, last.copyWith(parts: updatedParts));
    });
  }

  Future<void> addToolOutput({
    required String toolCallId,
    required String toolState,
    Object? output,
    String? errorText,
  }) {
    return _jobExecutor.run(() async {
      final messages = state.messages;
      if (messages.isEmpty) return;

      final last = messages.last;
      final updatedParts = last.parts.map((part) {
        if (part['toolCallId'] != toolCallId) return part;
        return <String, Object?>{
          ...part,
          'state': toolState,
          if (output != null) 'output': output,
          if (errorText != null) 'errorText': errorText,
        };
      }).toList(growable: false);

      state.replaceMessage(
          messages.length - 1, last.copyWith(parts: updatedParts));
    });
  }

  Future<void> _makeRequest({
    required String trigger,
    String? messageId,
    required UiChatRequestOptions options,
  }) async {
    state.status = UiChatStatus.submitted;
    state.error = null;

    final cancelToken = core.CancelToken();
    _activeCancelToken = cancelToken;

    var isAbort = false;
    var isError = false;
    UiMessageStreamFinishEvent? finishEvent;

    try {
      Stream<Map<String, Object?>> chunks;

      if (trigger == 'resume-stream') {
        final reconnect = transport.reconnectToStream;
        if (reconnect == null) return;
        final stream = await Future.value(
          reconnect(
            chatId: id,
            headers: options.headers,
            body: options.body,
            metadata: options.metadata,
          ),
        );
        if (stream == null) return;
        chunks = stream;
      } else {
        chunks = await Future.value(
          transport.sendMessages(
            chatId: id,
            messages: state.messages,
            trigger: trigger,
            messageId: messageId,
            headers: options.headers,
            body: options.body,
            metadata: options.metadata,
            cancelToken: cancelToken,
          ),
        );
      }

      final wrappedChunks = handleUiMessageStreamFinish(
        chunks: chunks,
        messageId: generateId(),
        originalMessages: state.messages,
        onFinish: (evt) => finishEvent = evt,
        onError: _onError,
      );

      final baseAssistant = state.snapshot(_lastAssistantMessage);
      var didStream = false;

      await for (final snapshot in readUiMessageStream(
        chunks: wrappedChunks,
        message: baseAssistant,
        terminateOnError: true,
        onError: _onError,
      )) {
        if (!didStream) {
          didStream = true;
          state.status = UiChatStatus.streaming;
        }

        final index = state.messages.indexWhere((m) => m.id == snapshot.id);
        if (index >= 0) {
          state.replaceMessage(index, snapshot);
        } else {
          state.pushMessage(snapshot);
        }
      }

      state.status = UiChatStatus.ready;
    } catch (e) {
      if (e is core.CancelledError) {
        isAbort = true;
        state.status = UiChatStatus.ready;
      } else {
        isError = true;
        state.status = UiChatStatus.error;
        state.error = e;
        _onError?.call(e);
      }
    } finally {
      final evt = finishEvent;
      if (evt != null) {
        final wasCancelled = cancelToken.isCancelled;
        _onFinish?.call(
          UiChatFinishEvent(
            message: evt.responseMessage,
            messages: evt.messages,
            isAbort: isAbort || wasCancelled || evt.isAborted,
            isError: isError,
            finishReason: evt.finishReason,
          ),
        );
      }
      _activeCancelToken = null;
    }
  }
}
