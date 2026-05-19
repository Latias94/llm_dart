import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/replay_stream_channel.dart';
import 'chat_ui_message.dart';

enum ChatUiStepObservationPhase {
  start,
  finish,
}

/// Reader-level step-boundary observation snapshot.
///
/// This stays below `ChatSession` and above raw `ChatUiStreamChunk` so direct
/// chunk-stream consumers can observe both step starts and finishes without
/// introducing a callback-heavy facade.
final class ChatUiStepObservation {
  final ChatUiStepObservationPhase phase;
  final String? stepId;
  final ChatUiMessage message;

  const ChatUiStepObservation({
    required this.phase,
    required this.stepId,
    required this.message,
  });

  bool get isStart => phase == ChatUiStepObservationPhase.start;

  bool get isFinish => phase == ChatUiStepObservationPhase.finish;
}

final class ChatUiStreamReadResult extends StreamView<ChatUiMessage> {
  final Future<ChatUiMessage> result;

  /// Unified reader-level stream for both step-start and step-finish
  /// boundaries.
  final Stream<ChatUiStepObservation> stepEvents;
  final Stream<ChatUiMessage> stepFinishStream;
  final Stream<DataUiPart<Object?>> transientDataParts;

  ChatUiStreamReadResult._({
    required Stream<ChatUiMessage> stream,
    required this.result,
    required this.stepEvents,
    required this.stepFinishStream,
    required this.transientDataParts,
  }) : super(stream);

  Stream<ChatUiMessage> get messageStream => this;

  Future<FinishReason?> get finishReason => result.then(
        (value) =>
            value.metadata[ChatUiMetadataKeys.finishReason] as FinishReason?,
      );

  Future<bool> get isAborted => result.then(
        (value) => value.metadata[ChatUiMetadataKeys.isAborted] == true,
      );

  Future<String?> get abortReason => result.then(
        (value) => value.metadata[ChatUiMetadataKeys.abortReason] as String?,
      );
}

final class ChatUiStreamReadSink {
  final ReplayStreamChannel<ChatUiMessage> _messageChannel =
      ReplayStreamChannel<ChatUiMessage>();
  final ReplayStreamChannel<ChatUiStepObservation> _stepEventChannel =
      ReplayStreamChannel<ChatUiStepObservation>();
  final ReplayStreamChannel<ChatUiMessage> _stepFinishChannel =
      ReplayStreamChannel<ChatUiMessage>();
  final ReplayStreamChannel<DataUiPart<Object?>> _transientChannel =
      ReplayStreamChannel<DataUiPart<Object?>>();
  final Completer<ChatUiMessage> _resultCompleter = Completer<ChatUiMessage>();

  late final ChatUiStreamReadResult readResult = ChatUiStreamReadResult._(
    stream: _messageChannel.stream,
    result: _resultCompleter.future,
    stepEvents: _stepEventChannel.stream,
    stepFinishStream: _stepFinishChannel.stream,
    transientDataParts: _transientChannel.stream,
  );

  void addMessage(ChatUiMessage message) {
    _messageChannel.add(message);
  }

  void addStepStart({
    required String? stepId,
    required ChatUiMessage message,
  }) {
    _stepEventChannel.add(
      ChatUiStepObservation(
        phase: ChatUiStepObservationPhase.start,
        stepId: stepId,
        message: message,
      ),
    );
  }

  void addStepFinish({
    required String? stepId,
    required ChatUiMessage message,
  }) {
    final observation = ChatUiStepObservation(
      phase: ChatUiStepObservationPhase.finish,
      stepId: stepId,
      message: message,
    );
    _stepEventChannel.add(observation);
    _stepFinishChannel.add(message);
  }

  void addTransientDataPart(DataUiPart<Object?> part) {
    _transientChannel.add(part);
  }

  void close(ChatUiMessage finalMessage) {
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.complete(finalMessage);
    }
    _messageChannel.close();
    _stepEventChannel.close();
    _stepFinishChannel.close();
    _transientChannel.close();
  }

  void fail(Object error, StackTrace stackTrace) {
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(error, stackTrace);
    }
    _messageChannel.addError(error, stackTrace);
    _stepEventChannel.addError(error, stackTrace);
    _stepFinishChannel.addError(error, stackTrace);
    _transientChannel.addError(error, stackTrace);
  }
}
