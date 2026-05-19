import 'dart:async';

import '../stream/text_stream_event.dart';
import 'chat_ui_accumulator.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_accumulator.dart';
import 'chat_ui_stream_chunk.dart';
import 'chat_ui_stream_read_result.dart';
export 'chat_ui_stream_read_result.dart'
    show
        ChatUiStepObservation,
        ChatUiStepObservationPhase,
        ChatUiStreamReadResult;

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

final class ChatUiStreamReader {
  final ChatUiStreamAccumulator _accumulator;
  final ChatUiMessageMetadataValidator? _messageMetadataValidator;
  final ChatUiDataPartValidator? _dataPartValidator;
  final ChatUiStreamReadSink _readSink = ChatUiStreamReadSink();

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

  ChatUiStreamReadResult get readResult => _readSink.readResult;

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
        _readSink.addTransientDataPart(
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
        _readSink.addMessage(message);
        if (chunk case ChatUiEventChunk(event: final event)) {
          switch (event) {
            case StepStartEvent():
              _readSink.addStepStart(
                stepId: event.stepId,
                message: message,
              );
            case StepFinishEvent():
              _readSink.addStepFinish(
                stepId: event.stepId,
                message: message,
              );
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
    _readSink.close(_accumulator.message);
  }

  void fail(Object error, StackTrace stackTrace) {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    _readSink.fail(error, stackTrace);
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
