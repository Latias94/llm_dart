import 'dart:async';

import '../stream/text_stream_event.dart';
import 'chat_ui_accumulator.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_accumulator.dart';
import 'chat_ui_stream_chunk.dart';
import 'chat_ui_stream_read_result.dart';
import 'chat_ui_stream_validation.dart';
export 'chat_ui_stream_read_result.dart'
    show
        ChatUiStepObservation,
        ChatUiStepObservationPhase,
        ChatUiStreamReadResult;
export 'chat_ui_stream_validation.dart'
    show
        ChatUiDataPartValidationContext,
        ChatUiDataPartValidator,
        ChatUiMessageMetadataValidationContext,
        ChatUiMessageMetadataValidationPhase,
        ChatUiMessageMetadataValidator;

final class ChatUiStreamReader {
  final ChatUiStreamAccumulator _accumulator;
  final ChatUiStreamValidator _validator;
  final ChatUiStreamReadSink _readSink = ChatUiStreamReadSink();

  bool _isClosed = false;

  ChatUiStreamReader({
    required String messageId,
    ChatUiRole role = ChatUiRole.assistant,
    ChatUiMessage? seedMessage,
    ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
    ChatUiMessageMetadataValidator? messageMetadataValidator,
    ChatUiDataPartValidator? dataPartValidator,
  })  : _validator = ChatUiStreamValidator(
          messageMetadataValidator: messageMetadataValidator,
          dataPartValidator: dataPartValidator,
        ),
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
    _validator.validateMessageMetadataPatch(
      phase: phase,
      message: _accumulator.message,
      messageId: messageId,
      patch: patch,
    );
  }

  void _validateDataPart(
    DataUiPart<Object?> part, {
    required bool isTransient,
  }) {
    _validator.validateDataPart(
      part,
      message: _accumulator.message,
      isTransient: isTransient,
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
