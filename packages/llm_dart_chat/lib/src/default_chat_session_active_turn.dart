import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_session_tool_support.dart';
import 'chat_state.dart';

typedef ChatStateReader = ChatState Function();
typedef ChatStateEmitter = void Function(ChatState state);
typedef ChatAssistantMessageUpserter = void Function(
  ChatUiMessage assistantMessage,
);
typedef ChatAssistantPromptAppender = void Function(
  ChatUiMessage assistantMessage, {
  required int startPartIndex,
});
typedef ChatTransientDataPartEmitter = void Function(
  DataUiPart<Object?> part,
);
typedef ChatAutomaticToolExecutionScheduler = void Function();
typedef ChatSessionErrorMapper = ModelError Function(Object error);

final class DefaultChatSessionActiveTurn {
  final ChatStateReader readState;
  final ChatStateEmitter emitState;
  final ChatAssistantMessageUpserter upsertAssistantMessage;
  final ChatAssistantPromptAppender appendAssistantPromptIfPresent;
  final ChatTransientDataPartEmitter emitTransientDataPart;
  final ChatAutomaticToolExecutionScheduler scheduleAutomaticToolExecution;
  final ChatSessionErrorMapper mapError;

  StreamSubscription<ChatUiStreamChunk>? _subscription;
  ChatUiStreamReader? _streamReader;
  Completer<void>? _completion;
  int _promptAppendStartIndex = 0;

  DefaultChatSessionActiveTurn({
    required this.readState,
    required this.emitState,
    required this.upsertAssistantMessage,
    required this.appendAssistantPromptIfPresent,
    required this.emitTransientDataPart,
    required this.scheduleAutomaticToolExecution,
    required this.mapError,
  });

  bool get hasActiveTurn => _subscription != null;

  bool applyDataPart<T>(DataUiPart<T> part) {
    final streamReader = _streamReader;
    if (streamReader == null) {
      return false;
    }

    upsertAssistantMessage(streamReader.applyDataPart(part));
    return true;
  }

  Future<void> consume({
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

    _streamReader = streamReader;
    _completion = completion;
    _promptAppendStartIndex = promptAppendStartIndex;

    if (seedAssistantMessage != null && syntheticStepStartOnSeed) {
      latestAssistantMessage = streamReader.applyEvent(
        const StepStartEvent(),
      );
      upsertAssistantMessage(latestAssistantMessage);
    }

    void failAssistantTurn(Object error, StackTrace stackTrace) {
      if (_completion != completion || completed) {
        return;
      }

      completed = true;
      streamReader.close();
      unawaited(_subscription?.cancel());
      clear();
      emitState(
        readState().copyWith(
          status: ChatStatus.error,
          error: mapError(error),
        ),
      );
      _completeIfNeeded(completion);
    }

    _subscription = stream.listen(
      (chunk) {
        try {
          final projectedMessage = streamReader.applyChunk(chunk);
          switch (chunk) {
            case ChatUiTransientDataPartChunk(:final part):
              emitTransientDataPart(
                DataUiPart<Object?>(
                  id: part.id,
                  key: part.key,
                  data: part.data,
                ),
              );
            case ChatUiEventChunk(:final event):
              latestAssistantMessage = projectedMessage;
              upsertAssistantMessage(projectedMessage);

              if (event is ErrorEvent) {
                completed = true;
                streamReader.close();
                unawaited(_subscription?.cancel());
                clear();
                emitState(
                  readState().copyWith(
                    status: ChatStatus.error,
                    error: event.error,
                  ),
                );
                _completeIfNeeded(completion);
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
              upsertAssistantMessage(projectedMessage);
          }
        } catch (error, stackTrace) {
          failAssistantTurn(error, stackTrace);
        }
      },
      onError: (error, stackTrace) {
        failAssistantTurn(error, stackTrace);
      },
      onDone: () {
        if (completed || _completion != completion) {
          return;
        }

        streamReader.close();

        if (latestAssistantMessage != null) {
          appendAssistantPromptIfPresent(
            latestAssistantMessage!,
            startPartIndex: promptAppendStartIndex,
          );
        }

        clear();
        emitState(
          readState().copyWith(
            status: chatDeriveCompletionStatus(latestAssistantMessage),
            error: null,
          ),
        );
        scheduleAutomaticToolExecution();
        _completeIfNeeded(completion);
      },
      cancelOnError: false,
    );

    await completion.future;
  }

  Future<void> stop() async {
    final subscription = _subscription;
    if (subscription == null) {
      return;
    }

    final streamReader = _streamReader;
    if (streamReader != null) {
      final abortedMessage = streamReader.applyEvent(
        const AbortEvent(),
      );
      upsertAssistantMessage(abortedMessage);
      final assistantMessage = streamReader.applyEvent(
        const FinishEvent(
          finishReason: FinishReason.aborted,
        ),
      );
      upsertAssistantMessage(assistantMessage);
      appendAssistantPromptIfPresent(
        assistantMessage,
        startPartIndex: _promptAppendStartIndex,
      );
    }

    await subscription.cancel();
    final completion = _completion;
    clear();
    emitState(
      readState().copyWith(
        status: ChatStatus.ready,
        error: null,
      ),
    );
    if (completion != null) {
      _completeIfNeeded(completion);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    final completion = _completion;
    if (completion != null) {
      _completeIfNeeded(completion);
    }
    clear();
  }

  void clear() {
    _subscription = null;
    _streamReader = null;
    _completion = null;
    _promptAppendStartIndex = 0;
  }

  void _completeIfNeeded(Completer<void> completion) {
    if (!completion.isCompleted) {
      completion.complete();
    }
  }
}
