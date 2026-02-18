import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'read_ui_message_stream.dart';
import 'ui_messages.dart';

typedef UiMessageStreamOnFinishCallback = FutureOr<void> Function(
  UiMessageStreamFinishEvent event,
);

typedef UiMessageStreamOnStepFinishCallback = FutureOr<void> Function(
  UiMessageStreamStepFinishEvent event,
);

class UiMessageStreamFinishEvent {
  final bool isAborted;
  final bool isContinuation;
  final UIMessage responseMessage;
  final List<UIMessage> messages;
  final String? finishReason;

  const UiMessageStreamFinishEvent({
    required this.isAborted,
    required this.isContinuation,
    required this.responseMessage,
    required this.messages,
    required this.finishReason,
  });
}

class UiMessageStreamStepFinishEvent {
  final bool isContinuation;
  final UIMessage responseMessage;
  final List<UIMessage> messages;

  const UiMessageStreamStepFinishEvent({
    required this.isContinuation,
    required this.responseMessage,
    required this.messages,
  });
}

Stream<Map<String, Object?>> handleUiMessageStreamFinish({
  required Stream<Map<String, Object?>> chunks,
  String? messageId,
  List<UIMessage> originalMessages = const <UIMessage>[],
  UiMessageStreamOnStepFinishCallback? onStepFinish,
  UiMessageStreamOnFinishCallback? onFinish,
  void Function(Object error)? onError,
  IdGenerator? generateId,
}) {
  // Persistence mode: if the last original message is an assistant message, we
  // continue it and reuse its id.
  UIMessage? lastMessage =
      originalMessages.isEmpty ? null : originalMessages.last;
  if (lastMessage?.role != 'assistant') {
    lastMessage = null;
  } else {
    messageId = lastMessage!.id;
  }

  final state = createStreamingUIMessageState(
    lastMessage: lastMessage,
    messageId: messageId,
    generateId: generateId,
  );

  final controller = StreamController<Map<String, Object?>>(sync: true);
  late final StreamSubscription<Map<String, Object?>> sub;

  var finishCalled = false;
  var chain = Future<void>.value();

  bool isContinuation() =>
      lastMessage != null && state.message.id == lastMessage.id;

  List<UIMessage> buildMessagesSnapshot() {
    if (!isContinuation()) {
      return <UIMessage>[
        ...originalMessages,
        deepCloneUiMessage(state.message),
      ];
    }
    return <UIMessage>[
      ...originalMessages.take(originalMessages.length - 1),
      deepCloneUiMessage(state.message),
    ];
  }

  Future<void> callOnFinish() async {
    if (finishCalled || onFinish == null) return;
    finishCalled = true;
    try {
      await Future.value(
        onFinish(
          UiMessageStreamFinishEvent(
            isAborted: state.isAborted,
            isContinuation: isContinuation(),
            responseMessage: deepCloneUiMessage(state.message),
            messages: buildMessagesSnapshot(),
            finishReason: state.finishReason,
          ),
        ),
      );
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> callOnStepFinish() async {
    final cb = onStepFinish;
    if (cb == null) return;
    try {
      await Future.value(
        cb(
          UiMessageStreamStepFinishEvent(
            isContinuation: isContinuation(),
            responseMessage: deepCloneUiMessage(state.message),
            messages: buildMessagesSnapshot(),
          ),
        ),
      );
    } catch (e) {
      onError?.call(e);
    }
  }

  void handleChunkError(Object error) {
    onError?.call(error);
  }

  sub = chunks.listen((chunk) {
    chain = chain.then((_) async {
      try {
        // Inject messageId into start chunk if missing and we have one.
        if (chunk['type'] == 'start' &&
            (chunk['messageId'] == null || chunk['messageId'] == '')) {
          final id = messageId;
          if (id != null && id.trim().isNotEmpty) {
            chunk = <String, Object?>{...chunk, 'messageId': id.trim()};
          }
        }

        try {
          applyUiMessageChunk(state, chunk);
        } catch (e) {
          handleChunkError(e);
        }

        if (chunk['type'] == 'finish-step') {
          await callOnStepFinish();
        }
        if (chunk['type'] == 'abort') {
          // Abort does not necessarily imply stream end; wait for completion.
          state.isAborted = true;
        }

        controller.add(chunk);
      } catch (e) {
        handleChunkError(e);
      }
    });
  }, onError: (e) {
    handleChunkError(e);
  }, onDone: () async {
    await chain;
    await callOnFinish();
    await controller.close();
  }, cancelOnError: false);

  controller.onCancel = () async {
    await chain;
    await callOnFinish();
    await sub.cancel();
  };

  return controller.stream;
}
