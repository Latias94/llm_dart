import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide
        CustomEvent,
        ErrorEvent,
        FileEvent,
        FinishEvent,
        RawChunkEvent,
        ReasoningDeltaEvent,
        ReasoningEndEvent,
        ReasoningFileEvent,
        ReasoningStartEvent,
        ResponseMetadataEvent,
        SourceEvent,
        StartEvent,
        TextDeltaEvent,
        TextEndEvent,
        TextStartEvent,
        ToolApprovalRequestEvent,
        ToolCallEvent,
        ToolInputDeltaEvent,
        ToolInputEndEvent,
        ToolInputErrorEvent,
        ToolInputStartEvent,
        ToolResultEvent;

import '../common/replay_stream_channel.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_accumulator.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_accumulator.dart';
import 'chat_ui_stream_chunk.dart';

enum ChatUiStepObservationPhase {
  start,
  finish,
}

enum ChatUiMessageMetadataValidationPhase {
  start,
  patch,
  finish,
}

final class ChatUiMessageMetadataValidationContext {
  final ChatUiMessageMetadataValidationPhase phase;
  final String messageId;
  final Map<String, Object?> currentMetadata;
  final Map<String, Object?> patch;
  final Map<String, Object?> nextMetadata;

  ChatUiMessageMetadataValidationContext({
    required this.phase,
    required this.messageId,
    required Map<String, Object?> currentMetadata,
    required Map<String, Object?> patch,
    required Map<String, Object?> nextMetadata,
  })  : currentMetadata = Map.unmodifiable(currentMetadata),
        patch = Map.unmodifiable(patch),
        nextMetadata = Map.unmodifiable(nextMetadata);
}

typedef ChatUiMessageMetadataValidator = void Function(
  ChatUiMessageMetadataValidationContext context,
);

final class ChatUiDataPartValidationContext {
  final ChatUiMessage message;
  final DataUiPart<Object?> part;
  final bool isTransient;

  const ChatUiDataPartValidationContext({
    required this.message,
    required this.part,
    required this.isTransient,
  });
}

typedef ChatUiDataPartValidator = void Function(
  ChatUiDataPartValidationContext context,
);

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

final class ChatUiStreamReader {
  final ChatUiStreamAccumulator _accumulator;
  final ChatUiMessageMetadataValidator? _messageMetadataValidator;
  final ChatUiDataPartValidator? _dataPartValidator;
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

  bool _isClosed = false;

  ChatUiStreamReader({
    required String messageId,
    ChatUiRole role = ChatUiRole.assistant,
    ChatUiMessage? seedMessage,
    ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
    ChatUiMessageMetadataValidator? messageMetadataValidator,
    ChatUiDataPartValidator? dataPartValidator,
  })  : _messageMetadataValidator = messageMetadataValidator,
        _dataPartValidator = dataPartValidator,
        _accumulator = ChatUiStreamAccumulator(
          messageId: messageId,
          role: role,
          seedMessage: seedMessage,
          options: options,
        );

  ChatUiMessage get message => _accumulator.message;

  Stream<ChatUiMessage> get messageStream => readResult.messageStream;

  Stream<ChatUiStepObservation> get stepEvents => readResult.stepEvents;

  Stream<ChatUiMessage> get stepFinishStream => readResult.stepFinishStream;

  Stream<DataUiPart<Object?>> get transientDataParts =>
      readResult.transientDataParts;

  Future<ChatUiMessage> get result => readResult.result;

  ChatUiMessage applyChunk(ChatUiStreamChunk chunk) {
    _ensureOpen('applyChunk');

    switch (chunk) {
      case ChatUiTransientDataPartChunk(:final part):
        _validateDataPart(
          DataUiPart<Object?>(
            id: part.id,
            key: part.key,
            data: part.data,
          ),
          isTransient: true,
        );
        _transientChannel.add(
          DataUiPart<Object?>(
            id: part.id,
            key: part.key,
            data: part.data,
          ),
        );
        return _accumulator.message;
      case ChatUiMessageStartChunk(:final messageId, :final metadata):
        _validateMessageMetadataPatch(
          phase: ChatUiMessageMetadataValidationPhase.start,
          messageId: messageId ?? _accumulator.message.id,
          patch: metadata,
        );
      case ChatUiMessageMetadataChunk(:final metadata):
        _validateMessageMetadataPatch(
          phase: ChatUiMessageMetadataValidationPhase.patch,
          messageId: _accumulator.message.id,
          patch: metadata,
        );
      case ChatUiDataPartChunk(:final part):
        _validateDataPart(
          DataUiPart<Object?>(
            id: part.id,
            key: part.key,
            data: part.data,
          ),
          isTransient: false,
        );
      case ChatUiMessageFinishChunk(:final metadata):
        _validateMessageMetadataPatch(
          phase: ChatUiMessageMetadataValidationPhase.finish,
          messageId: _accumulator.message.id,
          patch: metadata,
        );
      case _:
        break;
    }

    switch (chunk) {
      case ChatUiTransientDataPartChunk():
        return _accumulator.message;
      case _:
        final message = _accumulator.apply(chunk);
        _messageChannel.add(message);
        if (chunk case ChatUiEventChunk(event: final event)) {
          switch (event) {
            case StepStartEvent():
              _stepEventChannel.add(
                ChatUiStepObservation(
                  phase: ChatUiStepObservationPhase.start,
                  stepId: event.stepId,
                  message: message,
                ),
              );
            case StepFinishEvent():
              final observation = ChatUiStepObservation(
                phase: ChatUiStepObservationPhase.finish,
                stepId: event.stepId,
                message: message,
              );
              _stepEventChannel.add(observation);
              _stepFinishChannel.add(message);
            case _:
              break;
          }
        }
        return message;
    }
  }

  ChatUiMessage applyEvent(TextStreamEvent event) {
    return applyChunk(ChatUiEventChunk(event));
  }

  ChatUiMessage applyDataPart<T>(DataUiPart<T> part) {
    return applyChunk(ChatUiDataPartChunk<T>(part));
  }

  Future<void> consume(Stream<ChatUiStreamChunk> chunks) async {
    _ensureOpen('consume');

    try {
      await for (final chunk in chunks) {
        applyChunk(chunk);
      }
      close();
    } catch (error, stackTrace) {
      fail(error, stackTrace);
    }
  }

  void close() {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.complete(_accumulator.message);
    }
    _messageChannel.close();
    _stepEventChannel.close();
    _stepFinishChannel.close();
    _transientChannel.close();
  }

  void fail(Object error, StackTrace stackTrace) {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(error, stackTrace);
    }
    _messageChannel.addError(error, stackTrace);
    _stepEventChannel.addError(error, stackTrace);
    _stepFinishChannel.addError(error, stackTrace);
    _transientChannel.addError(error, stackTrace);
  }

  void _ensureOpen(String operation) {
    if (_isClosed) {
      throw StateError(
        'Cannot call ChatUiStreamReader.$operation after the reader has closed.',
      );
    }
  }

  void _validateMessageMetadataPatch({
    required ChatUiMessageMetadataValidationPhase phase,
    required String messageId,
    required Map<String, Object?> patch,
  }) {
    final validator = _messageMetadataValidator;
    if (validator == null || patch.isEmpty) {
      return;
    }

    final currentMetadata = _accumulator.message.metadata;
    final nextMetadata = <String, Object?>{
      ...currentMetadata,
      ...patch,
    };

    validator(
      ChatUiMessageMetadataValidationContext(
        phase: phase,
        messageId: messageId,
        currentMetadata: currentMetadata,
        patch: patch,
        nextMetadata: nextMetadata,
      ),
    );
  }

  void _validateDataPart(
    DataUiPart<Object?> part, {
    required bool isTransient,
  }) {
    final validator = _dataPartValidator;
    if (validator == null) {
      return;
    }

    validator(
      ChatUiDataPartValidationContext(
        message: _accumulator.message,
        part: part,
        isTransient: isTransient,
      ),
    );
  }
}

ChatUiStreamReadResult readChatUiStream({
  required Stream<ChatUiStreamChunk> chunks,
  required String messageId,
  ChatUiRole role = ChatUiRole.assistant,
  ChatUiMessage? seedMessage,
  ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
  ChatUiMessageMetadataValidator? messageMetadataValidator,
  ChatUiDataPartValidator? dataPartValidator,
}) {
  final reader = ChatUiStreamReader(
    messageId: messageId,
    role: role,
    seedMessage: seedMessage,
    options: options,
    messageMetadataValidator: messageMetadataValidator,
    dataPartValidator: dataPartValidator,
  );
  unawaited(reader.consume(chunks));
  return reader.readResult;
}
