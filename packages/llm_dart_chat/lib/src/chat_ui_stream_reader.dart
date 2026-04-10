import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'replay_stream_channel.dart';

final class ChatUiStreamReadResult extends StreamView<ChatUiMessage> {
  final Future<ChatUiMessage> result;
  final Stream<ChatUiMessage> stepFinishStream;
  final Stream<DataUiPart<Object?>> transientDataParts;

  ChatUiStreamReadResult._({
    required Stream<ChatUiMessage> stream,
    required this.result,
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

ChatUiStreamReadResult readChatUiStream({
  required Stream<ChatUiStreamChunk> chunks,
  required String messageId,
  ChatUiRole role = ChatUiRole.assistant,
  ChatUiMessage? seedMessage,
  ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
}) {
  final messageChannel = ReplayStreamChannel<ChatUiMessage>();
  final stepFinishChannel = ReplayStreamChannel<ChatUiMessage>();
  final transientChannel = ReplayStreamChannel<DataUiPart<Object?>>();
  final resultCompleter = Completer<ChatUiMessage>();

  unawaited(
    _processChatUiStream(
      chunks: chunks,
      messageId: messageId,
      role: role,
      seedMessage: seedMessage,
      options: options,
      messageChannel: messageChannel,
      stepFinishChannel: stepFinishChannel,
      transientChannel: transientChannel,
      resultCompleter: resultCompleter,
    ),
  );

  return ChatUiStreamReadResult._(
    stream: messageChannel.stream,
    result: resultCompleter.future,
    stepFinishStream: stepFinishChannel.stream,
    transientDataParts: transientChannel.stream,
  );
}

Future<void> _processChatUiStream({
  required Stream<ChatUiStreamChunk> chunks,
  required String messageId,
  required ChatUiRole role,
  required ChatUiMessage? seedMessage,
  required ChatUiAccumulatorOptions options,
  required ReplayStreamChannel<ChatUiMessage> messageChannel,
  required ReplayStreamChannel<ChatUiMessage> stepFinishChannel,
  required ReplayStreamChannel<DataUiPart<Object?>> transientChannel,
  required Completer<ChatUiMessage> resultCompleter,
}) async {
  final accumulator = ChatUiStreamAccumulator(
    messageId: messageId,
    role: role,
    seedMessage: seedMessage,
    options: options,
  );
  var latestMessage = accumulator.message;

  try {
    await for (final chunk in chunks) {
      switch (chunk) {
        case ChatUiTransientDataPartChunk(:final part):
          final transientPart = DataUiPart<Object?>(
            id: part.id,
            key: part.key,
            data: part.data,
          );
          transientChannel.add(transientPart);
        case _:
          latestMessage = accumulator.apply(chunk);
          messageChannel.add(latestMessage);
          if (chunk case ChatUiEventChunk(event: final event)
              when event is StepFinishEvent) {
            stepFinishChannel.add(latestMessage);
          }
      }
    }

    if (!resultCompleter.isCompleted) {
      resultCompleter.complete(latestMessage);
    }
    messageChannel.close();
    stepFinishChannel.close();
    transientChannel.close();
  } catch (error, stackTrace) {
    if (!resultCompleter.isCompleted) {
      resultCompleter.completeError(error, stackTrace);
    }
    messageChannel.addError(error, stackTrace);
    stepFinishChannel.addError(error, stackTrace);
    transientChannel.addError(error, stackTrace);
  }
}
