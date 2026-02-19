import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart' as core;

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

typedef UiChatOnToolCallCallback = FutureOr<void> Function({
  required Map<String, Object?> toolCall,
});

typedef UiChatOnDataCallback = void Function(Map<String, Object?> dataPart);

typedef UiChatSendAutomaticallyWhen = FutureOr<bool> Function({
  required List<UIMessage> messages,
});

class UiChatFinishEvent {
  final UIMessage message;
  final List<UIMessage> messages;
  final bool isAbort;
  final bool isDisconnect;
  final bool isError;
  final String? finishReason;

  const UiChatFinishEvent({
    required this.message,
    required this.messages,
    required this.isAbort,
    this.isDisconnect = false,
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
  final UiChatOnToolCallCallback? onToolCall;
  final UiChatOnFinishCallback? onFinish;
  final UiChatOnDataCallback? onData;
  final UiChatSendAutomaticallyWhen? sendAutomaticallyWhen;

  const UiChatInit({
    required this.transport,
    this.id,
    this.messages,
    this.generateId,
    this.onError,
    this.onToolCall,
    this.onFinish,
    this.onData,
    this.sendAutomaticallyWhen,
  });
}

class _ActiveResponse {
  StreamingUIMessageState state;
  final core.CancelToken cancelToken;

  _ActiveResponse({
    required this.state,
    required this.cancelToken,
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
  final UiChatOnToolCallCallback? _onToolCall;
  final UiChatOnFinishCallback? _onFinish;
  final UiChatOnDataCallback? _onData;
  final UiChatSendAutomaticallyWhen? _sendAutomaticallyWhen;

  final SerialJobExecutor _jobExecutor = SerialJobExecutor();

  _ActiveResponse? _activeResponse;
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
        _onToolCall = init.onToolCall,
        _onFinish = init.onFinish,
        _onData = init.onData,
        _sendAutomaticallyWhen = init.sendAutomaticallyWhen,
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
    if (state.status != UiChatStatus.streaming &&
        state.status != UiChatStatus.submitted) {
      return;
    }
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
  }) =>
      send(text: text, options: options);

  /// Appends or replaces a user message and submits it.
  ///
  /// If [messageId] is provided, the existing user message is replaced and all
  /// messages after it are removed (AI SDK parity).
  ///
  /// If [text], [parts], and [files] are all null, this submits the current
  /// message list without adding a new message.
  Future<void> send({
    String? text,
    List<Map<String, Object?>>? parts,
    List<Map<String, Object?>>? files,
    Object? metadata,
    String? messageId,
    UiChatRequestOptions options = const UiChatRequestOptions(),
  }) async {
    final hasContent = text != null || parts != null || files != null;

    // Submit without adding a new message.
    if (!hasContent) {
      await _makeRequest(
        trigger: 'submit-message',
        messageId: _lastMessage?.id,
        options: options,
      );
      return;
    }

    final mergedParts = <Map<String, Object?>>[
      ...?files,
      ...?parts,
      if (text != null) {'type': 'text', 'text': text},
    ];

    if (messageId != null) {
      await _jobExecutor.run(() async {
        final messages = state.messages;
        final idx = messages.indexWhere((m) => m.id == messageId);
        if (idx == -1) {
          throw StateError('message with id $messageId not found');
        }
        if (messages[idx].role != 'user') {
          throw StateError('message with id $messageId is not a user message');
        }

        state.messages = messages.take(idx + 1).toList(growable: false);
        state.replaceMessage(
          idx,
          UIMessage(
            id: messageId,
            role: 'user',
            metadata: metadata,
            parts: mergedParts,
          ),
        );
      });

      await _makeRequest(
        trigger: 'submit-message',
        messageId: messageId,
        options: options,
      );
      return;
    }

    await _jobExecutor.run(() async {
      state.pushMessage(
        UIMessage(
          id: generateId(),
          role: 'user',
          metadata: metadata,
          parts: mergedParts,
        ),
      );
    });

    await _makeRequest(
      trigger: 'submit-message',
      messageId: null,
      options: options,
    );
  }

  Future<void> regenerate({
    String? messageId,
    UiChatRequestOptions options = const UiChatRequestOptions(),
  }) async {
    await _jobExecutor.run(() async {
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
    });

    await _makeRequest(
      trigger: 'regenerate-message',
      messageId: messageId,
      options: options,
    );
  }

  Future<void> resumeStream({
    UiChatRequestOptions options = const UiChatRequestOptions(),
  }) async {
    await _makeRequest(trigger: 'resume-stream', options: options);
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

      bool update(UIMessage message) {
        var changed = false;
        for (final part in message.parts) {
          if (part['toolCallId'] == null) continue;
          if (part['state'] != 'approval-requested') continue;

          final approval = part['approval'];
          if (approval is! Map) continue;
          final approvalId = approval['id'];
          if (approvalId != id) continue;

          changed = true;
          part['state'] = 'approval-responded';
          part['approval'] = <String, Object?>{
            'id': id,
            'approved': approved,
            if (reason != null) 'reason': reason,
          };
        }
        return changed;
      }

      final didUpdateState = update(last);
      final active = _activeResponse;
      if (active != null) {
        update(active.state.message);
      }

      if (didUpdateState) {
        state.replaceMessage(messages.length - 1, last);
      }
    }).then((_) async {
      if (state.status == UiChatStatus.streaming ||
          state.status == UiChatStatus.submitted) {
        return;
      }

      if (_sendAutomaticallyWhen == null) return;
      final shouldSend = await _shouldSendAutomatically();
      if (!shouldSend) return;

      // Do not await to avoid deadlocks with serialized updates.
      unawaited(
        _makeRequest(
          trigger: 'submit-message',
          messageId: _lastMessage?.id,
          options: const UiChatRequestOptions(),
        ),
      );
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

      bool update(UIMessage message) {
        var changed = false;
        for (final part in message.parts) {
          if (part['toolCallId'] != toolCallId) continue;
          changed = true;
          part['state'] = toolState;
          if (output != null) {
            part['output'] = output;
          }
          if (errorText != null) {
            part['errorText'] = errorText;
          }
        }
        return changed;
      }

      final didUpdateState = update(last);
      final active = _activeResponse;
      if (active != null) {
        update(active.state.message);
      }

      if (didUpdateState) {
        state.replaceMessage(messages.length - 1, last);
      }
    }).then((_) async {
      if (state.status == UiChatStatus.streaming ||
          state.status == UiChatStatus.submitted) {
        return;
      }

      if (_sendAutomaticallyWhen == null) return;
      final shouldSend = await _shouldSendAutomatically();
      if (!shouldSend) return;

      // Do not await to avoid deadlocks with serialized updates.
      unawaited(
        _makeRequest(
          trigger: 'submit-message',
          messageId: _lastMessage?.id,
          options: const UiChatRequestOptions(),
        ),
      );
    });
  }

  Future<bool> _shouldSendAutomatically() async {
    final cb = _sendAutomaticallyWhen;
    if (cb == null) return false;
    return await Future<bool>.value(cb(messages: state.messages));
  }

  static bool _isDisconnectError(Object error) {
    if (error is TimeoutException) return true;

    final message = error.toString().toLowerCase();
    if (message.contains('socketexception')) return true;
    if (message.contains('clientexception')) return true;
    if (message.contains('failed host lookup')) return true;
    if (message.contains('host lookup')) return true;

    // Generic network-ish terms across platforms/runtimes.
    if (message.contains('network')) return true;
    if (message.contains('connection') &&
        (message.contains('closed') ||
            message.contains('reset') ||
            message.contains('refused') ||
            message.contains('aborted') ||
            message.contains('terminated'))) {
      return true;
    }

    if (message.contains('timed out') || message.contains('timeout'))
      return true;

    // AI SDK parity: fetch/network errors are treated as disconnects.
    if (message.contains('fetch')) return true;

    return false;
  }

  Future<void> _makeRequest({
    required String trigger,
    String? messageId,
    required UiChatRequestOptions options,
  }) async {
    var isAbort = false;
    var isDisconnect = false;
    var isError = false;

    _ActiveResponse? activeResponse;
    core.CancelToken? cancelToken;

    try {
      Stream<Map<String, Object?>>? stream;

      // For resume-stream, check if there's an active stream before changing
      // status. This avoids a brief flash of `submitted` when there is no stream
      // to resume (e.g. on page load).
      if (trigger == 'resume-stream') {
        final reconnect = transport.reconnectToStream;
        if (reconnect == null) return;
        try {
          stream = await Future.value(
            reconnect(
              chatId: id,
              headers: options.headers,
              body: options.body,
              metadata: options.metadata,
            ),
          );
        } catch (e) {
          state.status = UiChatStatus.error;
          state.error = e;
          _onError?.call(e);
          return;
        }

        if (stream == null) return;
      }

      state.status = UiChatStatus.submitted;
      state.error = null;

      final lastMessage = _lastMessage;

      cancelToken = core.CancelToken();
      cancelToken!.addListener((_) {
        isAbort = true;
      });
      _activeCancelToken = cancelToken;

      activeResponse = _ActiveResponse(
        state: createStreamingUIMessageState(
          lastMessage: state.snapshot(lastMessage),
          messageId: generateId(),
          generateId: generateId,
        ),
        cancelToken: cancelToken!,
      );

      _activeResponse = activeResponse;

      void write() {
        state.status = UiChatStatus.streaming;

        final shouldReplace =
            activeResponse!.state.message.id == _lastMessage?.id;
        if (shouldReplace) {
          state.replaceMessage(
            state.messages.length - 1,
            activeResponse!.state.message,
          );
        } else {
          state.pushMessage(activeResponse!.state.message);
        }
      }

      Future<void> runUpdateMessageJob(
        FutureOr<void> Function(StreamingUIMessageState state) job, {
        required bool shouldWrite,
      }) {
        return _jobExecutor.run(() async {
          await Future<void>.value(job(activeResponse!.state));
          if (shouldWrite) write();
        });
      }

      if (trigger != 'resume-stream') {
        stream = await Future.value(
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

      if (stream == null) return;

      await for (final chunk in stream) {
        final type = chunk['type'];
        if (type is! String || type.isEmpty) continue;

        // Data parts use `type: data-*`.
        if (type.startsWith('data-')) {
          final dataPart = <String, Object?>{
            'type': type,
            if (chunk['id'] is String && (chunk['id'] as String).isNotEmpty)
              'id': chunk['id'] as String,
            'data': chunk['data'],
            if (chunk['transient'] == true) 'transient': true,
          };

          _onData?.call(dataPart);
          if (chunk['transient'] == true) {
            continue;
          }
        }

        final shouldWrite = switch (type) {
          'finish-step' => false,
          'start-step' => false,
          'error' => false,
          'start' =>
            chunk['messageId'] != null || chunk['messageMetadata'] != null,
          'finish' => chunk['messageMetadata'] != null,
          'message-metadata' => chunk['messageMetadata'] != null,
          _ => true,
        };

        if (type == 'tool-input-available') {
          await runUpdateMessageJob(
            (s) {
              applyUiMessageChunk(s, chunk);
            },
            shouldWrite: shouldWrite,
          );

          if (_onToolCall != null && chunk['providerExecuted'] != true) {
            await Future<void>.value(
              _onToolCall!(toolCall: Map<String, Object?>.from(chunk)),
            );
          }
          continue;
        }

        await runUpdateMessageJob(
          (s) {
            applyUiMessageChunk(s, chunk);
          },
          shouldWrite: shouldWrite,
        );
      }

      state.status = UiChatStatus.ready;
    } catch (e) {
      final cancelled = e is core.CancelledError ||
          cancelToken?.isCancelled == true ||
          _activeCancelToken?.isCancelled == true;

      if (cancelled) {
        isAbort = true;
        state.status = UiChatStatus.ready;
      } else {
        isError = true;

        isDisconnect = _isDisconnectError(e);

        state.status = UiChatStatus.error;
        state.error = e;
        _onError?.call(e);
      }
    } finally {
      try {
        final message = activeResponse?.state.message;
        if (message != null) {
          _onFinish?.call(
            UiChatFinishEvent(
              message: message,
              messages: state.messages,
              isAbort: isAbort || (activeResponse?.state.isAborted ?? false),
              isDisconnect: isDisconnect,
              isError: isError,
              finishReason: activeResponse?.state.finishReason,
            ),
          );
        }
      } catch (_) {
        // Ignore finish callback errors.
      }

      _activeCancelToken = null;
      _activeResponse = null;
    }

    // Automatically send messages based on the sendAutomaticallyWhen callback.
    if (!isError && await _shouldSendAutomatically()) {
      await _makeRequest(
        trigger: 'submit-message',
        messageId: _lastMessage?.id,
        options: options,
      );
    }
  }
}
