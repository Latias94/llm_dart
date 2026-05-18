import 'dart:async';

import '../stream/text_stream_event.dart';
import '../ui/chat_ui_message.dart';
import '../ui/chat_ui_stream_chunk.dart';
import '../ui/chat_ui_stream_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_foundation.dart';
import 'stream_result_foundation.dart';

final class StreamOutputResult<T> {
  final StreamResultController<OutputStreamEvent<T>, GenerateOutputResult<T>>
      _foundation =
      StreamResultController<OutputStreamEvent<T>, GenerateOutputResult<T>>();
  late final StreamSideChannel<Object?> _partialOutputChannel;
  late final StreamSideChannel<Object?> _elementChannel;

  StreamOutputResult._(Stream<OutputStreamEvent<T>> source) {
    _partialOutputChannel = _foundation.createSideChannel<Object?>();
    _elementChannel = _foundation.createSideChannel<Object?>();
    source.listen(
      _handleEvent,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: true,
    );
  }

  Stream<OutputStreamEvent<T>> get eventStream => _foundation.eventStream;

  Stream<TextStreamEvent> get textStream =>
      eventStream.transform<TextStreamEvent>(
        StreamTransformer<OutputStreamEvent<T>, TextStreamEvent>.fromHandlers(
          handleData: (event, sink) {
            if (event case OutputTextStreamEvent<T>(:final streamEvent)) {
              sink.add(streamEvent);
            }
          },
        ),
      );

  Stream<Object?> get partialOutputStream => _partialOutputChannel.stream;

  Stream<TElement> elementStream<TElement>() =>
      _elementChannel.stream.cast<TElement>();

  Stream<ChatUiStreamChunk> chatUiStream({
    String? messageId,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
  }) {
    return projectTextStreamEventStream(
      textStream,
      messageId: messageId,
      messageMetadata: messageMetadata,
      leadingDataParts: leadingDataParts,
      finalMessageMetadata: finalMessageMetadata,
    );
  }

  Future<GenerateOutputResult<T>> get result => _foundation.result;

  Future<T> get output => result.then((value) => value.output);

  Future<String> get text => result.then((value) => value.text);

  Future<String?> get reasoningText =>
      result.then((value) => value.reasoningText);

  Future<FinishReason> get finishReason =>
      result.then((value) => value.finishReason);

  Future<String?> get rawFinishReason =>
      result.then((value) => value.rawFinishReason);

  Future<ModelResponseMetadata?> get responseMetadata =>
      result.then((value) => value.responseMetadata);

  Future<String?> get responseId => result.then((value) => value.responseId);

  Future<DateTime?> get responseTimestamp =>
      result.then((value) => value.responseTimestamp);

  Future<String?> get responseModelId =>
      result.then((value) => value.responseModelId);

  Future<UsageStats?> get usage => result.then((value) => value.usage);

  Future<ProviderMetadata?> get providerMetadata =>
      result.then((value) => value.providerMetadata);

  void _handleEvent(OutputStreamEvent<T> event) {
    _foundation.addEvent(event);

    switch (event) {
      case OutputTextStreamEvent<T>():
        break;
      case OutputPartialEvent<T>(:final partialOutput):
        _partialOutputChannel.add(partialOutput);
      case OutputElementEvent(:final element):
        _elementChannel.add(element);
      case OutputResultEvent<T>(:final result):
        _foundation.completeResult(result);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _foundation.fail(error, stackTrace);
  }

  void _handleDone() {
    if (!_foundation.isResultCompleted) {
      _handleError(
        StateError(
          'streamOutputResult completed without emitting an OutputResultEvent.',
        ),
        StackTrace.current,
      );
      return;
    }

    _foundation.close();
  }
}

typedef StreamObjectResult<T> = StreamOutputResult<T>;

StreamOutputResult<T> createStreamOutputResult<T>(
  Stream<OutputStreamEvent<T>> source,
) {
  return StreamOutputResult<T>._(source);
}
